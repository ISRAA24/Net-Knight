class RuleModel {
  final String tableName;
  final String chainName;
  final String ipSource;
  final String ipDestination;
  final String portDestination;
  final String interface;
  final String protocol;
  final String action;
  final String family; // ← اتضاف

  const RuleModel({
    required this.tableName,
    required this.chainName,
    required this.ipSource,
    required this.ipDestination,
    required this.portDestination,
    required this.interface,
    required this.protocol,
    required this.action,
    this.family = 'ip', // ← default ip
  });

  Map<String, dynamic> toJson() => {
        'tableName': tableName,
        'chainName': chainName,
        'ipSource': ipSource,
        'ipDestination': ipDestination,
        'portDestination': portDestination,
        'interface': interface,
        'protocol': protocol,
        'action': action,
        'family': family,
      };
}
