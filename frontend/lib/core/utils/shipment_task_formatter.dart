import '../../features/smart_tasks/models/smart_task_model.dart';

/// ─── Formatted Task Item ──────────────────────────────────────────────────────

class FormattedTaskItem {
  final SmartTaskModel task;
  final String priorityIcon;
  final String displayTitle;
  final int? overdueDays;
  final bool isDuplicateWithPrevious;

  const FormattedTaskItem({
    required this.task,
    required this.priorityIcon,
    required this.displayTitle,
    this.overdueDays,
    this.isDuplicateWithPrevious = false,
  });
}

/// ─── Unified Shipment Task Output Formatter ───────────────────────────────────

class ShipmentTaskFormatter {
  // ── 1. Client Short Name (Rule 2) ──────────────────────────────────────────

  /// Extracts `<first word of client name>`.
  /// Single fallback: if the first word is a generic prefix with no identifying value
  /// (e.g. "Al", "The", "Company", "شركة", "الشركة", "مؤسسة", "مجموعة"), uses the first two words.
  static String formatClientShortName(String clientName) {
    final clean = clientName.trim();
    if (clean.isEmpty) return '';

    final tokens = clean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return '';
    if (tokens.length == 1) return tokens.first;

    const genericPrefixes = {
      'al',
      'the',
      'company',
      'group',
      'corp',
      'corporation',
      'شركة',
      'الشركة',
      'مؤسسة',
      'المؤسسة',
      'مجموعة',
      'المجموعة',
    };

    final firstLower = tokens.first.toLowerCase();
    if (genericPrefixes.contains(firstLower) && tokens.length > 1) {
      return '${tokens[0]} ${tokens[1]}';
    }

    return tokens.first;
  }

  /// Formats human-readable shipment identity: `<Shipment/product name> – <ClientShort>`.
  /// If [includeCode] is true, appends `([fileCode])`.
  /// Example: `PET Stock – SCAS` (or `PET Stock – SCAS (IMP-2026-0004)` if includeCode is true).
  static String formatShipmentLabel({
    required String shipmentName,
    required String clientName,
    String? fileCode,
    bool includeCode = false,
  }) {
    final shortClient = formatClientShortName(clientName);
    final base = shortClient.isNotEmpty ? '$shipmentName – $shortClient' : shipmentName;
    if (includeCode && fileCode != null && fileCode.trim().isNotEmpty) {
      return '$base ($fileCode)';
    }
    return base;
  }

  /// Cleans technical IDs, operation numbers, and step tags from task titles:
  /// - Strips `[IMP-2026-0004]`, `[IMP-...]`
  /// - Strips `[ACID: ...]`, `ACID: ...`
  /// - Strips `(STEP_03)`, `(STEP_07)`, `STEP_04`
  /// - Strips leading/trailing dashes and colons
  /// Leaves only the clear name of the screen, operation, or task!
  static String cleanTaskTitle(String rawTitle) {
    var s = rawTitle;
    // Strip [IMP-...] tags
    s = s.replaceAll(RegExp(r'\[\s*IMP-[^\]]+\]', caseSensitive: false), '');
    // Strip [ACID: ...] tags from task title
    s = s.replaceAll(RegExp(r'\[\s*ACID:\s*[^\]]+\]', caseSensitive: false), '');
    // Strip (STEP_03) / [STEP_03] / STEP_03
    s = s.replaceAll(RegExp(r'[\(\[]\s*STEP_\d+\s*[\)\]]', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'STEP_\d+', caseSensitive: false), '');
    // Clean up leading dashes, bullets, colons
    s = s.replaceAll(RegExp(r'^\s*[-—–•*:]+\s*'), '');
    s = s.replaceAll(RegExp(r'\s+[-—–]+\s*$'), '');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return s.isNotEmpty ? s : rawTitle.trim();
  }

  // ── 2. Priority Indicator (Rule 7) ─────────────────────────────────────────

  /// 🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low/Done.
  static String getPriorityIcon(String priority, {String status = ''}) {
    final st = status.trim().toLowerCase();
    if (st == 'completed' || st == 'done' || st == 'مكتمل' || st == 'مكتملة') {
      return '🟢';
    }

    switch (priority.trim().toLowerCase()) {
      case 'critical':
      case 'حرجة':
      case 'عاجل':
      case 'عاجلة':
        return '🔴';
      case 'high':
      case 'عالية':
      case 'مرتفع':
      case 'مرتفعة':
        return '🟠';
      case 'medium':
      case 'متوسطة':
      case 'متوسط':
        return '🟡';
      case 'low':
      case 'منخفضة':
      case 'منخفض':
      default:
        return '🟢';
    }
  }

  // ── 3. Completion Percentage & Visual Bar (Rule 8) ──────────────────────────

  /// Calculates completion percentage, color cue, and 10-block progress bar.
  /// 0–39%: 🔴 early stage
  /// 40–74%: 🟡 in progress
  /// 75–99%: 🟢 near completion
  /// 100%: ✅ complete
  static String formatCompletionIndicator({
    required int completedSteps,
    required int totalSteps,
    bool isArabic = true,
  }) {
    if (totalSteps <= 0) {
      return isArabic
          ? 'نسبة الإنجاز: 🔴 0% (0 من 0 خطوة مكتملة) ░░░░░░░░░░'
          : 'Completion Rate: 🔴 0% (0 of 0 steps completed) ░░░░░░░░░░';
    }

    final pct = ((completedSteps / totalSteps) * 100).round().clamp(0, 100);

    String colorIcon;
    if (pct >= 100) {
      colorIcon = '✅';
    } else if (pct >= 75) {
      colorIcon = '🟢';
    } else if (pct >= 40) {
      colorIcon = '🟡';
    } else {
      colorIcon = '🔴';
    }

    final filled = (pct / 10).round().clamp(0, 10);
    final empty = 10 - filled;
    final visualBar = '${"▓" * filled}${"░" * empty}';

    if (isArabic) {
      return 'نسبة الإنجاز: $colorIcon $pct% ($completedSteps من $totalSteps خطوة مكتملة) $visualBar';
    } else {
      return 'Completion Rate: $colorIcon $pct% ($completedSteps of $totalSteps steps completed) $visualBar';
    }
  }

  // ── 4. Date Comparison & Overdue Days (Rule 1) ─────────────────────────────

  /// Parses date string into DateTime. Supports YYYY-MM-DD, DD/MM/YYYY, etc.
  static DateTime? parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    try {
      final isoMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
      if (isoMatch != null) {
        return DateTime(
          int.parse(isoMatch.group(1)!),
          int.parse(isoMatch.group(2)!),
          int.parse(isoMatch.group(3)!),
        );
      }

      final dmyMatch = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(s);
      if (dmyMatch != null) {
        return DateTime(
          int.parse(dmyMatch.group(3)!),
          int.parse(dmyMatch.group(2)!),
          int.parse(dmyMatch.group(1)!),
        );
      }

      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  /// Calculates overdue days compared to [now]. Positive number means overdue.
  static int? calculateOverdueDays(String? dueDateStr, DateTime now) {
    final due = parseDate(dueDateStr);
    if (due == null) return null;

    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = today.difference(dueDay).inDays;
    return diff > 0 ? diff : null;
  }

  // ── 5. Deduplication Detection (Rule 5) ────────────────────────────────────

  /// Checks if two task titles represent near-duplicate steps.
  static bool areNearDuplicates(String titleA, String titleB, {String? phaseA, String? phaseB}) {
    if (phaseA != null && phaseB != null && phaseA.isNotEmpty && phaseA == phaseB) {
      return true;
    }

    final cleanA = titleA.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ').trim().toLowerCase();
    final cleanB = titleB.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ').trim().toLowerCase();

    if (cleanA == cleanB) return true;

    final wordsA = cleanA.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final wordsB = cleanB.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return false;

    final intersection = wordsA.intersection(wordsB).length;
    final smallerSize = wordsA.length < wordsB.length ? wordsA.length : wordsB.length;

    // >60% overlap in substantive words
    return (intersection / smallerSize) >= 0.6;
  }

  // ── 6. Arabic Pluralization Helpers ────────────────────────────────────────

  static String _formatTaskCountArabic(int count) {
    if (count == 1) return 'مهمة واحدة متأخرة';
    if (count == 2) return 'مهمتان متأخرتان';
    if (count >= 3 && count <= 10) return '$count مهام متأخرة';
    return '$count مهمة متأخرة';
  }

  static String _formatDaysArabic(int days) {
    if (days == 1) return 'يوم واحد';
    if (days == 2) return 'يومين';
    if (days >= 3 && countDays(days) <= 10) return '$days أيام';
    return '$days يوماً';
  }

  static int countDays(int d) => d % 100 >= 3 && d % 100 <= 10 ? d % 100 : 0;

  // ── 7. Single Clear Next Action (Rule 6) ────────────────────────────────────

  static String formatNextAction(String taskTitle, {bool isArabic = true}) {
    final cleanTitle = taskTitle.replaceAll(RegExp(r'^\s*[-•*]\s*'), '').trim();

    if (isArabic) {
      String missingInput = 'البيانات والمستندات المطلوبة';
      if (cleanTitle.contains('GOEIC') || cleanTitle.contains('فحص مسبق')) {
        missingInput = 'بيانات شهادة GOEIC';
      } else if (cleanTitle.contains('COO') || cleanTitle.contains('شهادة المنشأ')) {
        missingInput = 'بيانات شهادة المنشأ (COO)';
      } else if (cleanTitle.contains('حاوية') || cleanTitle.contains('سيل') || cleanTitle.contains('VGM')) {
        missingInput = 'أرقام الحاويات والسيول وأوزان VGM';
      } else if (cleanTitle.contains('بوليصة') || cleanTitle.contains('BL') || cleanTitle.contains('حجز')) {
        missingInput = 'رقم الحجز ومسودة بوليصة الشحن';
      } else if (cleanTitle.contains('ACID') || cleanTitle.contains('نافذة')) {
        missingInput = 'رقم القيد الجمركي المبدئي ACID';
      } else if (cleanTitle.contains('نموذج 4') || cleanTitle.contains('Form 4')) {
        missingInput = 'بيانات التحويل البنكي ونموذج 4';
      }

      return 'المطلوب منك الآن: $missingInput عشان نقفل أقدم مهمة متأخرة.';
    } else {
      String missingInput = 'required details and documents';
      if (cleanTitle.contains('GOEIC') || cleanTitle.contains('Pre-Shipment') || cleanTitle.contains('فحص مسبق')) {
        missingInput = 'GOEIC certificate data';
      } else if (cleanTitle.contains('COO') || cleanTitle.contains('Origin') || cleanTitle.contains('شهادة المنشأ')) {
        missingInput = 'Certificate of Origin (COO) details';
      } else if (cleanTitle.contains('Container') || cleanTitle.contains('Seal') || cleanTitle.contains('VGM') || cleanTitle.contains('حاوية')) {
        missingInput = 'container numbers, seals, and VGM weights';
      } else if (cleanTitle.contains('Booking') || cleanTitle.contains('B/L') || cleanTitle.contains('BL') || cleanTitle.contains('بوليصة')) {
        missingInput = 'booking number and draft Bill of Lading';
      } else if (cleanTitle.contains('ACID') || cleanTitle.contains('Nafeza') || cleanTitle.contains('نافذة')) {
        missingInput = 'ACID registration number';
      } else if (cleanTitle.contains('Form 4') || cleanTitle.contains('Bank') || cleanTitle.contains('نموذج 4')) {
        missingInput = 'bank transfer details and Form 4';
      }

      return 'What is needed now: $missingInput in order to close oldest overdue task.';
    }
  }

  // ── 8. Full Unified Task List Output Formatter (All Rules) ─────────────────

  static String formatTaskList({
    required String shipmentName,
    required String clientName,
    String? fileCode,
    int? completedSteps,
    int? totalSteps,
    required List<SmartTaskModel> tasks,
    DateTime? renderTime,
    bool isArabic = true,
  }) {
    final now = renderTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final shipmentLabel = formatShipmentLabel(
      shipmentName: shipmentName,
      clientName: clientName,
      fileCode: fileCode,
      includeCode: fileCode != null && fileCode.isNotEmpty,
    );

    // Filter pending/active tasks
    final activeTasks = tasks.where((t) => t.status != 'Completed' && t.status != 'Cancelled').toList();

    // Edge Case: All tasks done / 100% complete
    final isAllDone = activeTasks.isEmpty || (completedSteps != null && totalSteps != null && completedSteps >= totalSteps);
    if (isAllDone) {
      final buffer = StringBuffer();
      buffer.writeln(isArabic ? 'شحنة $shipmentLabel' : 'Shipment $shipmentLabel');
      if (completedSteps != null && totalSteps != null) {
        buffer.writeln(formatCompletionIndicator(completedSteps: totalSteps, totalSteps: totalSteps, isArabic: isArabic));
      }
      buffer.write(isArabic ? '✅ اكتملت جميع مراحل الشحنة بنجاح.' : '✅ All shipment stages completed successfully.');
      return buffer.toString();
    }

    // Classify tasks into Overdue, Due Today, Upcoming
    final List<SmartTaskModel> overdueTasks = [];
    final List<SmartTaskModel> dueTodayTasks = [];
    final List<SmartTaskModel> upcomingTasks = [];

    for (final t in activeTasks) {
      final due = parseDate(t.dueDate);
      if (due == null) {
        upcomingTasks.add(t);
        continue;
      }
      final dueDay = DateTime(due.year, due.month, due.day);
      if (dueDay.isBefore(today)) {
        overdueTasks.add(t);
      } else if (dueDay.isAtSameMomentAs(today)) {
        dueTodayTasks.add(t);
      } else {
        upcomingTasks.add(t);
      }
    }

    // Sort each group ascending by due date
    int compareDueAsc(SmartTaskModel a, SmartTaskModel b) {
      final da = parseDate(a.dueDate) ?? DateTime(2099);
      final db = parseDate(b.dueDate) ?? DateTime(2099);
      return da.compareTo(db);
    }

    overdueTasks.sort(compareDueAsc);
    dueTodayTasks.sort(compareDueAsc);
    upcomingTasks.sort(compareDueAsc);

    final buffer = StringBuffer();

    // ── Rule 1: Status-First Alert Line ──────────────────────────────────────
    if (overdueTasks.isNotEmpty) {
      final earliestTask = overdueTasks.first;
      final earliestDays = calculateOverdueDays(earliestTask.dueDate, now) ?? 1;
      if (isArabic) {
        final countStr = _formatTaskCountArabic(overdueTasks.length);
        final daysStr = _formatDaysArabic(earliestDays);
        buffer.writeln('⚠️ $countStr منذ $daysStr — شحنة $shipmentLabel');
      } else {
        final countStr = '${overdueTasks.length} ${overdueTasks.length == 1 ? "task" : "tasks"}';
        final daysStr = '$earliestDays ${earliestDays == 1 ? "day" : "days"}';
        buffer.writeln('⚠️ $countStr overdue since $daysStr — shipment $shipmentLabel');
      }
    } else {
      buffer.writeln(isArabic ? 'شحنة $shipmentLabel' : 'Shipment $shipmentLabel');
    }

    // ── Rule 8: Shipment Completion Indicator ────────────────────────────────
    if (completedSteps != null && totalSteps != null) {
      buffer.writeln(formatCompletionIndicator(completedSteps: completedSteps, totalSteps: totalSteps, isArabic: isArabic));
    }
    buffer.writeln();

    // ── Edge Case: Single task only ──────────────────────────────────────────
    if (activeTasks.length == 1) {
      final single = activeTasks.first;
      final icon = getPriorityIcon(single.priority, status: single.status);
      final overdue = calculateOverdueDays(single.dueDate, now);
      final overdueTag = overdue != null
          ? (isArabic ? ' (متأخرة منذ ${_formatDaysArabic(overdue)})' : ' (overdue by $overdue ${overdue == 1 ? "day" : "days"})')
          : '';
      final cleanedTitle = cleanTaskTitle(single.title);
      buffer.writeln('$icon $cleanedTitle$overdueTag');
      buffer.writeln();
      buffer.write(formatNextAction(cleanedTitle, isArabic: isArabic));
      return buffer.toString();
    }

    // Helper to render a group of tasks with deduplication checks (Rule 4 & 5)
    void renderTaskGroup(String header, List<SmartTaskModel> groupList, {bool showOverdueDays = false}) {
      if (groupList.isEmpty) return;
      buffer.writeln('$header:');

      for (int i = 0; i < groupList.length; i++) {
        final task = groupList[i];
        final icon = getPriorityIcon(task.priority, status: task.status);
        final overdue = showOverdueDays ? calculateOverdueDays(task.dueDate, now) : null;
        final overdueTag = overdue != null
            ? (isArabic ? ' (متأخرة منذ ${_formatDaysArabic(overdue)})' : ' (overdue by $overdue ${overdue == 1 ? "day" : "days"})')
            : '';
        final cleanedTitle = cleanTaskTitle(task.title);

        buffer.writeln('$icon $cleanedTitle$overdueTag');

        // Deduplication check with subsequent task
        if (i + 1 < groupList.length) {
          final nextTask = groupList[i + 1];
          if (areNearDuplicates(task.title, nextTask.title, phaseA: task.phaseName, phaseB: nextTask.phaseName)) {
            final nextIcon = getPriorityIcon(nextTask.priority, status: nextTask.status);
            final nextOverdue = showOverdueDays ? calculateOverdueDays(nextTask.dueDate, now) : null;
            final nextOverdueTag = nextOverdue != null
                ? (isArabic ? ' (متأخرة منذ ${_formatDaysArabic(nextOverdue)})' : ' (overdue by $nextOverdue ${nextOverdue == 1 ? "day" : "days"})')
                : '';
            final nextCleanedTitle = cleanTaskTitle(nextTask.title);
            buffer.writeln('$nextIcon $nextCleanedTitle$nextOverdueTag');
            buffer.writeln(isArabic
                ? '⚠️ يبدو تكرار بين هاتين المهمتين — برجاء التأكد من النظام'
                : '⚠️ Potential duplicate between these tasks — please verify in the system');
            i++; // skip next task as it was rendered here
          }
        }
      }
      buffer.writeln();
    }

    // ── Rule 1: Three-Group Ordering: Overdue → Due Today → Upcoming ─────────
    renderTaskGroup(isArabic ? 'متأخرة' : 'Overdue', overdueTasks, showOverdueDays: true);
    renderTaskGroup(isArabic ? 'مستحقة اليوم' : 'Due today', dueTodayTasks);
    renderTaskGroup(isArabic ? 'قادمة' : 'Upcoming', upcomingTasks);

    // ── Rule 6: Single Clear Next Action ─────────────────────────────────────
    final mostUrgent = overdueTasks.isNotEmpty
        ? overdueTasks.first
        : (dueTodayTasks.isNotEmpty ? dueTodayTasks.first : upcomingTasks.first);
    buffer.write(formatNextAction(mostUrgent.title, isArabic: isArabic));

    return buffer.toString().trimRight();
  }
}
