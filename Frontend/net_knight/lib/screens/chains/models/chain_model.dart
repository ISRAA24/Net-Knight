class ChainModel {
  final String tableName;
  final String chainName;
  final String hook;
  final String policy;
  final String type;
  final int priority;
  final String family; // ← اتضاف

  const ChainModel({
    required this.tableName,
    required this.chainName,
    required this.hook,
    required this.policy,
    required this.type,
    required this.priority,
    this.family = 'ip', // ← default ip
  });

  Map<String, dynamic> toJson() => {
        'tableName': tableName,
        'name': chainName,
        'hook': hook,
        'policy': policy,
        'type': type,
        'priority': priority,
        'family': family,
      };
}
