import 'package:net_knight/core/network/base_services.dart';
import '../models/notification_model.dart';

class NotificationService {
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await BaseService.dio.get('/notifications');
      if (response.data is List) {
        return (response.data as List).map((e) => NotificationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
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
      await BaseService.dio.patch('/notifications/mark-all-read');
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