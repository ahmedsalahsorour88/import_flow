import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/notifications_provider.dart';

class NotificationBellWidget extends ConsumerWidget {
  const NotificationBellWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(notificationsProvider);

    return asyncNotifs.when(
      loading: () => const IconButton(
        icon: Icon(Icons.notifications_none, color: Colors.white70),
        onPressed: null,
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_off, color: Colors.white38),
        onPressed: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
      ),
      data: (notifs) {
        final unreadList = notifs.where((n) => !n.isRead).toList();
        final unreadCount = unreadList.length;

        return PopupMenuButton<void>(
          tooltip: 'إشعارات النظام والتنبيهات',
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications, color: Colors.white, size: 24),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: unreadList.any((n) => n.severity == 'CRITICAL')
                          ? AppTheme.crimson
                          : AppTheme.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              enabled: false,
              child: SizedBox(
                width: 360,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'التنبيهات والإشعارات ($unreadCount)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            ref.read(notificationsProvider.notifier).triggerExpiryCheck();
                            Navigator.pop(context);
                          },
                          child: const Text('فحص الصلاحيات', style: TextStyle(fontSize: 11)),
                        ),
                        if (unreadCount > 0)
                          TextButton(
                            onPressed: () {
                              ref.read(notificationsProvider.notifier).markAllAsRead();
                              Navigator.pop(context);
                            },
                            child: const Text('قراءة الكل', style: TextStyle(fontSize: 11, color: AppTheme.cobalt)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            if (notifs.isEmpty)
              const PopupMenuItem<void>(
                enabled: false,
                child: SizedBox(
                  width: 360,
                  height: 60,
                  child: Center(
                    child: Text('لا توجد تنبيهات جديدة حالياً.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),
              )
            else
              ...notifs.take(8).map((n) => PopupMenuItem<void>(
                    onTap: () {
                      if (!n.isRead) {
                        ref.read(notificationsProvider.notifier).markAsRead(n.notificationId);
                      }
                    },
                    child: SizedBox(
                      width: 360,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.transparent : _getSeverityBgColor(n.severity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border(right: BorderSide(color: _getSeverityBgColor(n.severity), width: 3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(_getSeverityIcon(n.severity), size: 16, color: _getSeverityBgColor(n.severity)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.charcoal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.message,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }

  Color _getSeverityBgColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return AppTheme.crimson;
      case 'WARNING':
        return AppTheme.orange;
      default:
        return AppTheme.cobalt;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Icons.error_outline;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }
}
