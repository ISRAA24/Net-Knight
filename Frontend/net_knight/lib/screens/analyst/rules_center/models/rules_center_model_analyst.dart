import 'package:flutter/material.dart';

// ─── Firewall Rule ────────────────────────────────────────────
class FirewallRuleModelAnalyst {
  final String id;
  final bool enabled;
  final int priority;
  final String sourceIp;
  final String destination;
  final String port;
  final String protocol;
  final String action;
  final String created;
  final String origin;

  const FirewallRuleModelAnalyst({
    required this.id,
    required this.enabled,
    required this.priority,
    required this.sourceIp,
    required this.destination,
    required this.port,
    required this.protocol,
    required this.action,
    required this.created,
    required this.origin,
  });

  Color get actionColor => switch (action.toLowerCase()) {
        'drop' => const Color(0xFFEF4444),
        'accept' => const Color(0xFF22C55E),
        'nat' => const Color(0xFFF59E0B),
        _ => const Color(0xFF1D242B),
      };

  factory FirewallRuleModelAnalyst.fromJson(Map<String, dynamic> json) {
    // ⚠️ FIX: the backend's getAllRules controller does not return a
    // "priority" field at all (it lives on Chain, not on the rule itself),
    // so json['priority'] is always null. The old ternary checked
    // `(json['priority'] ?? 0) is int` (always true) but then assigned the
    // RAW json['priority'] (still null) to this non-nullable `int` field —
    // that threw a runtime TypeError on every single rule, which crashed
    // getFirewallRules() and made the whole Rules Center screen show
    // "Failed to load rules". We now properly default to 0.
    final rawPriority = json['priority'];
    final priority = rawPriority is int
        ? rawPriority
        : int.tryParse(rawPriority?.toString() ?? '') ?? 0;

    return FirewallRuleModelAnalyst(
      id: json['_id'] ?? json['id'] ?? '',
      enabled: json['isActive'] ?? json['enabled'] ?? true,
      priority: priority,
      sourceIp: json['sourceIp'] ?? json['ip_src'] ?? '-',
      destination: json['destination'] ?? json['ip_dest'] ?? '-',
      port: json['port'] ?? json['port_dest'] ?? '*',
      protocol: json['protocol'] ?? 'ANY',
      action: json['action'] ?? '-',
      created: json['createdAt'] ?? json['created'] ?? '',
      origin: json['ruleType'] ?? json['origin'] ?? 'Static',
    );
  }
}

// ─── NAT Rule ─────────────────────────────────────────────────
class NatRuleModelAnalyst {
  final String id;
  final bool enabled;
  final String sourceIp;
  final String interfaceName;
  final String destIp;
  final String newSourceIp;
  final String extPort;
  final String intPort;
  final String natType;
  final String created;

  const NatRuleModelAnalyst({
    required this.id,
    required this.enabled,
    required this.sourceIp,
    required this.interfaceName,
    required this.destIp,
    required this.newSourceIp,
    required this.extPort,
    required this.intPort,
    required this.natType,
    required this.created,
  });

  Color get natTypeColor => switch (natType.toLowerCase()) {
        'masquerade' => const Color(0xFF22C55E),
        'source' || 'snat' || 'source nat' => const Color(0xFF3B82F6),
        'destination' || 'dnat' || 'dest nat' => const Color(0xFFF59E0B),
        _ => const Color(0xFF1D242B),
      };

  factory NatRuleModelAnalyst.fromJson(Map<String, dynamic> json) {
    // ⚠️ FIX: destIp used to read json['new_source_ip'] FIRST (before
    // dest_ip), so a Source NAT rule's "Dest IP" column ended up showing
    // the *new source* IP instead of falling back to '—' (Source/
    // Masquerade rules have no real destination IP). newSourceIp is now
    // the only field reading new_source_ip, keeping the two concepts
    // separate instead of one leaking into the other.
    return NatRuleModelAnalyst(
      id: json['_id'] ?? json['id'] ?? '',
      enabled: json['isActive'] ?? json['enabled'] ?? true,
      sourceIp: json['source_ip'] ?? json['sourceIp'] ?? '—',
      interfaceName: json['output_interface'] ??
          json['input_interface'] ??
          json['interfaceName'] ??
          '—',
      destIp: json['dest_ip'] ?? json['destIp'] ?? '—',
      newSourceIp:
          json['new_source_ip']?.toString() ?? json['newSourceIp'] ?? '—',
      extPort: json['ext_port']?.toString() ?? json['extPort'] ?? '—',
      intPort: json['int_port']?.toString() ?? json['intPort'] ?? '—',
      natType: json['nat_type'] ?? json['natType'] ?? '',
      created: json['createdAt'] ?? json['created'] ?? '',
    );
  }
}

// ─── Combined Data ────────────────────────────────────────────
class RulesCenterDataAnalyst {
  final List<FirewallRuleModelAnalyst> firewallRules;
  final List<NatRuleModelAnalyst> natRules;

  const RulesCenterDataAnalyst({
    required this.firewallRules,
    required this.natRules,
  });
}

enum RuleViewAnalyst { firewall, nat }