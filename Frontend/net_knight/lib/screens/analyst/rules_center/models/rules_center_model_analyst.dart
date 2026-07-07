import 'package:flutter/material.dart';

// ─── Firewall Rule ────────────────────────────────────────────
class FirewallRuleModelAnalyst {
  final String id;
  final bool enabled;
  // ⚠️ NOTE: `priority` field removed entirely. The backend's
  // GET /staticfirewall/allRules never returns a real priority for a rule
  // (priority actually lives on the Chain document, not the Rule), so this
  // field was always either '-' or a wrong value (the nftables handleId).
  // Rather than keep a field that can never hold real data, it's been
  // dropped from the model — see FirewallTableAnalyst for the matching
  // column removal.
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
    return FirewallRuleModelAnalyst(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      enabled: json['isActive'] ?? json['enabled'] ?? true,
      sourceIp: (json['sourceIp'] ?? json['ip_src'] ?? '-').toString(),
      destination: (json['destination'] ?? json['ip_dest'] ?? '-').toString(),
      port: (json['port'] ?? json['port_dest'] ?? '*').toString(),
      protocol: (json['protocol'] ?? 'ANY').toString(),
      action: (json['action'] ?? '-').toString(),
      created: (json['createdAt'] ?? json['created'] ?? '').toString(),
      origin: (json['ruleType'] ?? json['origin'] ?? 'Static').toString(),
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
    // destIp/newSourceIp stay separate concepts: destIp only ever reads
    // dest_ip (Destination NAT), newSourceIp only ever reads new_source_ip
    // (Source NAT). The table widget derives the single "Translated
    // IP/Dest IP" display value itself, based on nat_type.
    return NatRuleModelAnalyst(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      enabled: json['isActive'] ?? json['enabled'] ?? true,
      sourceIp: (json['source_ip'] ?? json['sourceIp'] ?? '—').toString(),
      interfaceName: (json['output_interface'] ??
              json['input_interface'] ??
              json['interfaceName'] ??
              '—')
          .toString(),
      destIp: (json['dest_ip'] ?? json['destIp'] ?? '—').toString(),
      newSourceIp:
          (json['new_source_ip'] ?? json['newSourceIp'] ?? '—').toString(),
      extPort: (json['ext_port'] ?? json['extPort'] ?? '—').toString(),
      intPort: (json['int_port'] ?? json['intPort'] ?? '—').toString(),
      natType: (json['nat_type'] ?? json['natType'] ?? '').toString(),
      created: (json['createdAt'] ?? json['created'] ?? '').toString(),
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