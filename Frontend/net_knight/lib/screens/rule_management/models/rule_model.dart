class RuleModel {
  final String id;
  bool enabled;
  final int no;
  String sourceIp;
  String destIp;
  String port;
  String protocol;
  String action;

  RuleModel({
    required this.id,
    required this.enabled,
    required this.no,
    required this.sourceIp,
    required this.destIp,
    required this.port,
    required this.protocol,
    required this.action,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) => RuleModel(
        id: json['id']?.toString() ?? '',
        enabled: json['status'] ?? true,
        no: json['no'] ?? 0,
        sourceIp: json['sourceIp'] ?? 'Any',
        destIp: json['destIp'] ?? 'Any',
        port: json['port']?.toString() ?? 'Any',
        protocol: json['protocol'] ?? 'ANY',
        action: json['action'] ?? '',
      );
}

class NatRuleModel {
  final String id;
  bool enabled;
  final int no;
  String protocol;
  String externalIp;
  String internalIp;
  String internalPort;
  String action;

  NatRuleModel({
    required this.id,
    required this.enabled,
    required this.no,
    required this.protocol,
    required this.externalIp,
    required this.internalIp,
    required this.internalPort,
    required this.action,
  });

  factory NatRuleModel.fromJson(Map<String, dynamic> json) => NatRuleModel(
        id: json['id']?.toString() ?? '',
        enabled: json['status'] ?? true,
        no: json['no'] ?? 0,
        protocol: json['protocol'] ?? 'ANY',
        externalIp: json['externalIp'] ?? 'Any',
        internalIp: json['internalIp'] ?? 'Any',
        internalPort: json['internalPort']?.toString() ?? 'Any',
        action: json['action'] ?? '',
      );
}