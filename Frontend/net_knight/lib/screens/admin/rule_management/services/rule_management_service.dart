import 'package:net_knight/core/network/base_services.dart';
import '../models/rule_management_model.dart';

class RuleService {
  Future<List<RuleModel>> getAllRules() async {
    try {
      final response = await BaseService.dio.get('/staticfirewall/allRules');
      if (response.data is List) {
        return (response.data as List).map((e) => RuleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching rules: $e');
      return [];
    }
  }

  Future<List<NatRuleModel>> getNatRules() async {
    try {
      final response = await BaseService.dio.get('/staticfirewall/nat');
      if (response.data is List) {
        return (response.data as List).map((e) => NatRuleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching NAT rules: $e');
      return [];
    }
  }

  Future<bool> toggleRule(int priority, bool enabled) async {
    try {
      await BaseService.dio.post('/staticfirewall/toggleRule', data: {
        'priority': priority,
        'enabled': enabled,
      });
      return true;
    } catch (e) {
      print('Error toggling rule: $e');
      return false;
    }
  }

  Future<bool> deleteRule(int priority) async {
    try {
      await BaseService.dio.delete('/staticfirewall/rule/$priority');
      return true;
    } catch (e) {
      print('Error deleting rule: $e');
      return false;
    }
  }
}