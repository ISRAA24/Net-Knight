import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return GestureDetector(
      onTap: onMarkRead,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? const Color(0xFF18233A) : const Color(0xFF1E2128),
          borderRadius: BorderRadius.circular(14),
          border: unread ? Border.all(color: Colors.blue.withOpacity(0.12)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getIconBg(notification.type),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(notification.type), color: _getIconColor(notification.type), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: unread ? Colors.white : const Color(0xFFB0B8CC),
                      fontSize: 15,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.description,
                    style: TextStyle(
                      color: unread ? const Color(0xFF8A93A6) : const Color(0xFF6B7385),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        notification.time,
                        style: TextStyle(
                          color: unread ? const Color(0xFF8A93A6) : const Color(0xFF6B7385),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (unread) const Icon(Icons.circle, size: 8, color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  // ⚠️ FIX: the backend only ever sends `type` as one of
  // 'ai_rule_pending' | 'threat_alert' | 'traffic_spike'
  // (see Backend/src/models/notification.js + notificationHelper.js).
  // The old switch statements here compared against 'threat' / 'rule' /
  // 'system', which never matched anything, so every notification silently
  // fell back to the generic grey bell icon regardless of its real type.
  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'threat_alert':
        return Icons.warning_amber_rounded;
      case 'ai_rule_pending':
        return Icons.rule;
      case 'traffic_spike':
        return Icons.bolt;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconBg(String type) {
    switch (type.toLowerCase()) {
      case 'threat_alert':
        return Colors.red.withOpacity(0.2);
      case 'ai_rule_pending':
        return Colors.orange.withOpacity(0.2);
      case 'traffic_spike':
        return Colors.amber.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'threat_alert':
        return Colors.red;
      case 'ai_rule_pending':
        return Colors.orange;
      case 'traffic_spike':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
