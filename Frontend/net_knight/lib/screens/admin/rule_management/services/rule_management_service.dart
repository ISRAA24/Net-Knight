import 'package:dio/dio.dart';
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
  // ⚠️ FIX 2 (the actual bug behind "the toggle doesn't work"): the
  // `if (isAi)` branch below was missing its `else`, so EVERY toggle call
  // for an AI-generated rule ended up hitting BOTH endpoints:
  //   1. PATCH /ai/rules/:id/toggle          (correct — this succeeds)
  //   2. PATCH /staticfirewall/rules/:id/toggle  (wrong — this 404s, since
  //      that id only exists in the AIRule collection, not StaticRule)
  // The second call always threw, so the whole function always returned
  // false for AI rules — even though the backend had actually already
  // toggled the rule via call #1. The screen never refreshed after a
  // "failed" toggle, so the UI looked completely unresponsive.
  //
  // ⚠️ Backend note (not a frontend bug): re-enabling a previously
  // disabled AI rule is intentionally rejected by the backend with 501
  // ("Re-enabling a disabled AI rule is not supported by the firewall
  // agent yet. Delete this rule instead."). Toggling AI rules only works
  // in the disable direction — this method surfaces that specific error
  // message (via [RuleToggleException]) instead of a generic failure, so
  // the screen can show the real reason instead of just "Failed to
  // update rule".
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

  // ⚠️ FIX: '/staticfirewall/rule/$priority' was wrong on two counts:
  // the path segment is 'rules' (plural), and the identifier must be the
  // Mongo _id, not the (non-existent) "priority" field.
  Future<bool> deleteRule(String id, {bool isAi = false}) async {
    try {
      if (isAi) {
        // الـ Endpoint الخاص بالـ AI
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

/// Thrown by [RuleService.toggleRule] when the backend rejects the toggle
/// with a specific, user-relevant reason (e.g. the 501 "re-enabling AI
/// rules is not supported" case) instead of a generic connection failure.
class RuleToggleException implements Exception {
  final String message;
  const RuleToggleException(this.message);

  @override
  String toString() => message;
}