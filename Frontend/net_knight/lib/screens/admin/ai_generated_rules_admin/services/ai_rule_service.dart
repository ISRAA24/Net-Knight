import 'package:net_knight/core/network/base_services.dart';
import '../models/ai_rule_model.dart';

class AiRuleService {
  Future<List<AiRuleModel>> getAiRules() async {
    try {
      final response = await BaseService.dio.get('/ai/rules');
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => AiRuleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching AI rules: $e');
      return [];
    }
  }

  Future<bool> approveRule(String id) async {
    try {
      await BaseService.dio.put('/ai/rules/$id/review', data: {'decision': 'approve'});
      return true;
    } catch (e) {
      print('Error approving rule: $e');
      return false;
    }
  }

  Future<bool> rejectRule(String id) async {
    try {
      await BaseService.dio.put('/ai/rules/$id/review', data: {'decision': 'reject'});
      return true;
    } catch (e) {
      print('Error rejecting rule: $e');
      return false;
    }
  }

  Future<bool> toggleRule(String id) async {
    try {
      await BaseService.dio.patch('/ai/rules/$id/toggle');
      return true;
    } catch (e) {
      print('Error toggling rule: $e');
      return false;
    }
  }

  Future<bool> deleteRule(String id) async {
    try {
      await BaseService.dio.delete('/ai/rules/$id');
      return true;
    } catch (e) {
      print('Error deleting rule: $e');
      return false;
    }
  }

  Future<bool> getAutoApprove() async {
    try {
      final response = await BaseService.dio.get('/ai/settings/auto-approve');
      return response.data['autoApprove'] ?? false;
    } catch (e) {
      print('Error fetching auto-approve status: $e');
      return false;
    }
  }

  Future<bool> setAutoApprove(bool value) async {
    try {
      final response = await BaseService.dio.put(
        '/ai/settings/auto-approve',
        data: {'autoApprove': value},
      );
      return response.data['autoApprove'] ?? value;
    } catch (e) {
      print('Error setting auto-approve: $e');
      rethrow;
    }
  }
}