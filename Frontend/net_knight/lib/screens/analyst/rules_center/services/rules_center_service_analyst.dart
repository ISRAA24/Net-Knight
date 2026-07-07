import 'package:dio/dio.dart';
import 'package:net_knight/core/network/base_services.dart';
import '../models/rules_center_model_analyst.dart';

class RulesCenterServiceAnalyst {
  final Dio _dio = BaseService.dio;

  Future<List<FirewallRuleModelAnalyst>> getFirewallRules() async {
    final response = await _dio.get('/staticfirewall/allRules');
    final List data = response.data['data'] ?? [];
    final rules = <FirewallRuleModelAnalyst>[];
    for (final e in data) {
      try {
        if (e is Map) {
          rules.add(
            FirewallRuleModelAnalyst.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      } catch (err) {
        // ⚠️ FIX: `.map().toList()` is all-or-nothing — if a single row had
        // a shape .fromJson() didn't expect, the whole list construction
        // threw, which either surfaced as "Failed to load rules" or (worse)
        // silently left the table with zero rows while the rule count
        // badge — built from `_data?.firewallRules.length` after this
        // list already existed with data before the throw — could still
        // show a stale non-zero count. Skipping just the bad row keeps
        // every valid row on screen.
        // ignore: avoid_print
        print('Skipping malformed firewall rule: $err');
      }
    }
    return rules;
  }

  Future<List<NatRuleModelAnalyst>> getNatRules() async {
    final response = await _dio.get('/staticfirewall/nat');
    final List data = response.data['data'] ?? [];
    final rules = <NatRuleModelAnalyst>[];
    for (final e in data) {
      try {
        if (e is Map) {
          rules.add(
            NatRuleModelAnalyst.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      } catch (err) {
        // ignore: avoid_print
        print('Skipping malformed NAT rule: $err');
      }
    }
    return rules;
  }
}