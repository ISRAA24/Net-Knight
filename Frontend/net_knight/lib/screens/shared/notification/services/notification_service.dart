import 'package:net_knight/core/network/base_services.dart';
import '../models/notification_model.dart';

class NotificationService {
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await BaseService.dio.get('/notifications');
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => NotificationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await BaseService.dio.get('/notifications/unread-count');
      return response.data['count'] ?? 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await BaseService.dio.patch('/notifications/$id/read');
      return true;
    } catch (e) {
      print('Error marking notification read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await BaseService.dio.patch('/notifications/read-all');
      return true;
    } catch (e) {
      print('Error marking all read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await BaseService.dio.delete('/notifications/$id');
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  Future<bool> deleteAllNotifications() async {
    try {
      await BaseService.dio.delete('/notifications/clear-all');
      return true;
    } catch (e) {
      print('Error deleting all notifications: $e');
      return false;
    }
  }
}