import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/rule_management_model.dart';

class RuleService {

  Future<List<RuleModel>> getAllRules() async {
    try {
      final response = await BaseService.dio.get('/staticfirewall/allRules');
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => RuleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching rules: $e');
      return [];
    }
  }

  // ⚠️ FIX: same wrapped-response issue as above.
  Future<List<NatRuleModel>> getNatRules() async {
    try {
      final response = await BaseService.dio.get('/staticfirewall/nat');
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => NatRuleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching NAT rules: $e');
      return [];
    }
  }


  Future<bool> toggleRule(String id, {bool isAi = false}) async {
    try {
      if (isAi) {
        await BaseService.dio.patch('/ai/rules/$id/toggle');
      } else {
        await BaseService.dio.patch('/staticfirewall/rules/$id/toggle');
      }
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? e.message)
          : e.message;
      print('Error toggling rule: $message');
      throw RuleToggleException(message ?? 'Failed to update rule');
    } catch (e) {
      print('Error toggling rule: $e');
      return false;
    }
  }

  Future<bool> deleteRule(String id, {bool isAi = false}) async {
    try {
      if (isAi) {
        await BaseService.dio.delete('/ai/rules/$id');
      } else {
        await BaseService.dio.delete('/staticfirewall/rules/$id');
      }
      return true;
    } catch (e) {
      print('Error deleting rule: $e');
      return false;
    }
  }

  Future<bool> toggleNatRule(String id) async {
    try {
      await BaseService.dio.patch('/staticfirewall/nat/$id/toggle');
      return true;
    } catch (e) {
      print('Error toggling NAT rule: $e');
      return false;
    }
  }

  Future<bool> deleteNatRule(String id) async {
    try {
      await BaseService.dio.delete('/staticfirewall/nat/$id');
      return true;
    } catch (e) {
      print('Error deleting NAT rule: $e');
      return false;
    }
  }
}

class RuleToggleException implements Exception {
  final String message;
  const RuleToggleException(this.message);

  @override
  String toString() => message;
}