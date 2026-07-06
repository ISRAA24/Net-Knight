class RuleModel {
  final String id;
  bool enabled;
  final String ruleName;
  // ⚠️ ADDED: `priority` so the admin's Rules Center table can show the same
  // columns as the analyst's Rules Center table (Status, Priority, Source IP,
  // Destination, Port, Protocol, Action, Created, Origin). The backend's
  // GET /staticfirewall/allRules doesn't return this field today, so it
  // defaults to '-' the same way destination/port/protocol already did.
  final String priority;
  String sourceIp, destination, port, protocol, action;
  final String created, origin;
  final bool isAi;

  RuleModel({
    required this.id,
    required this.enabled,
    this.ruleName = '-',
    this.priority = '-',
    required this.sourceIp,
    required this.destination,
    required this.port,
    required this.protocol,
    required this.action,
    required this.created,
    required this.origin,
    this.isAi = false,
  });

  // NOTE: the backend's GET /staticfirewall/allRules does NOT return
  // priority/destination/port/protocol fields — it returns:
  // { _id, ruleName, sourceIp, action, ruleType, expireAt, isActive,
  //   isAi, createdAt }
  // so those extra fields are kept only for widget-layout compatibility
  // and default to '-' when the backend doesn't provide them.
    factory RuleModel.fromJson(Map<String, dynamic> json) {
    return RuleModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      enabled: json['isActive'] ?? json['enabled'] ?? true,
      ruleName: json['ruleName']?.toString() ?? '-',
      priority: json['priority']?.toString() ?? '-',
      sourceIp: json['sourceIp']?.toString() ?? json['ip_src']?.toString() ?? 'ANY',
      // إضافة ip_dest
      destination: json['destination']?.toString() ?? json['ip_dest']?.toString() ?? '-',
      // إضافة port_dest
      port: json['port']?.toString() ?? json['port_dest']?.toString() ?? '*',
      protocol: json['protocol']?.toString() ?? 'ANY',
      action: json['action']?.toString() ?? '-',
      created: json['createdAt']?.toString() ?? json['created']?.toString() ?? '',
      origin: json['ruleType']?.toString() ?? json['origin']?.toString() ?? 'Static',
      isAi: json['isAi'] ?? false,
    );
  }

}

class NatRuleModel {
  final String id;
  bool enabled;
  String sourceIp, interfaceName, destIp, extPort, intPort, natType, newSourceIp;
  final String created;

  NatRuleModel({
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

  factory NatRuleModel.fromJson(Map<String, dynamic> json) {
    return NatRuleModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      enabled: json['isActive'] ?? json['enabled'] ?? true,
      sourceIp: json['source_ip']?.toString() ?? json['sourceIp']?.toString() ?? 'ANY',
      interfaceName: json['output_interface']?.toString() ??
          json['input_interface']?.toString() ??
          json['interfaceName']?.toString() ??
          '',
      destIp: json['new_source_ip']?.toString() ?? json['dest_ip']?.toString() ?? json['destIp']?.toString() ?? '',
      newSourceIp: json['new_source_ip']?.toString() ?? json['newSourceIp']?.toString() ?? '',
      extPort: json['ext_port']?.toString() ?? json['extPort']?.toString() ?? '',
      intPort: json['int_port']?.toString() ?? json['intPort']?.toString() ?? '',
      natType: json['nat_type']?.toString() ?? json['natType']?.toString() ?? 'Masquerade',
      created: json['createdAt']?.toString() ?? json['created']?.toString() ?? '',
    );
  }
}

enum RuleView { firewall, nat }
