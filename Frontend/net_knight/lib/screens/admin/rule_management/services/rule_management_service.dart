import 'package:net_knight/core/network/base_services.dart';
import '../models/rule_management_model.dart';

class RuleService {
  // ⚠️ FIX: the backend returns { success, count, data: [...] } — not a
  // bare List — so `response.data is List` was always false and this
  // silently returned [] every time.
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

  // ⚠️ FIX: '/staticfirewall/toggleRule' doesn't exist on the backend.
  // The real route is PATCH /staticfirewall/rules/:id/toggle, keyed by the
  // Mongo _id (not the old "priority" field, which the backend model
  // doesn't even have).
  //
  // NOTE: AI-generated rules live in a different collection (AIRule) and
  // cannot be toggled through this endpoint — the caller must not invoke
  // this for rules where `isAi == true`.
  Future<bool> toggleRule(String id) async {
    try {
      await BaseService.dio.patch('/staticfirewall/rules/$id/toggle');
      return true;
    } catch (e) {
      print('Error toggling rule: $e');
      return false;
    }
  }

  // ⚠️ FIX: '/staticfirewall/rule/$priority' was wrong on two counts:
  // the path segment is 'rules' (plural), and the identifier must be the
  // Mongo _id, not the (non-existent) "priority" field.
  Future<bool> deleteRule(String id) async {
    try {
      await BaseService.dio.delete('/staticfirewall/rules/$id');
      return true;
    } catch (e) {
      print('Error deleting rule: $e');
      return false;
    }
  }

  // ⚠️ FIX: previously there was no method here at all — the screen's
  // _toggleNatRule() just called _loadData() without ever hitting the
  // backend, so the toggle button silently did nothing. The route already
  // exists on the backend (firewall.routes.js): PATCH /staticfirewall/nat/:id/toggle
  Future<bool> toggleNatRule(String id) async {
    try {
      await BaseService.dio.patch('/staticfirewall/nat/$id/toggle');
      return true;
    } catch (e) {
      print('Error toggling NAT rule: $e');
      return false;
    }
  }

  // ⚠️ FIX: same issue as toggleNatRule — the delete button did nothing.
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