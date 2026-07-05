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
}