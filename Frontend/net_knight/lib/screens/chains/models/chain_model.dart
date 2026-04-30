class ChainModel {
  final String tableName;
  final String chainName;
  final String hook;
  final String policy;
  final String type;
  final int priority;

  const ChainModel({
    required this.tableName,
    required this.chainName,
    required this.hook,
    required this.policy,
    required this.type,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'tableName': tableName,
        'name': chainName,
        'hook': hook,
        'policy': policy,
        'type': type,
        'priority': priority,
      };

  String toCommand() =>
      'nft add chain $type $tableName $chainName { type $type hook $hook priority $priority; policy $policy; }';
}
