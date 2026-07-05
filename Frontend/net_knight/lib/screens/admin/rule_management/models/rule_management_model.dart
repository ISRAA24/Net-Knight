class RuleModel {
  bool enabled;
  int priority;
  String sourceIp, destination, port, protocol, action;
  final String created, origin;

  RuleModel({
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

  factory RuleModel.fromJson(Map<String, dynamic> json) {
    return RuleModel(
      enabled: json['enabled'] ?? true,
      priority: json['priority'] ?? 10,
      sourceIp: json['sourceIp'] ?? 'ANY',
      destination: json['destination'] ?? 'ANY',
      port: json['port'] ?? '*',
      protocol: json['protocol'] ?? 'ANY',
      action: json['action'] ?? 'Drop',
      created: json['created'] ?? '',
      origin: json['origin'] ?? 'Static',
    );
  }
}

class NatRuleModel {
  bool enabled;
  String sourceIp, interfaceName, destIp, extPort, intPort, natType;
  final String created;

  NatRuleModel({
    required this.enabled,
    required this.sourceIp,
    required this.interfaceName,
    required this.destIp,
    required this.extPort,
    required this.intPort,
    required this.natType,
    required this.created,
  });

  factory NatRuleModel.fromJson(Map<String, dynamic> json) {
    return NatRuleModel(
      enabled: json['enabled'] ?? true,
      sourceIp: json['sourceIp'] ?? 'ANY',
      interfaceName: json['interfaceName'] ?? '',
      destIp: json['destIp'] ?? '',
      extPort: json['extPort'] ?? '',
      intPort: json['intPort'] ?? '',
      natType: json['natType'] ?? 'Masquerade',
      created: json['created'] ?? '',
    );
  }
}

enum RuleView { firewall, nat }