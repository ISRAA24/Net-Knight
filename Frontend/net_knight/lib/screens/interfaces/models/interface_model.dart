class InterfaceModel {
  final String logicalName;
  final String realName;
  final String status;
  final String ip;

  const InterfaceModel({
    required this.logicalName,
    required this.realName,
    required this.status,
    required this.ip,
  });

  String get initials =>
      logicalName.isNotEmpty ? logicalName.substring(0, 1).toUpperCase() : 'I';

  InterfaceModel copyWith({
    String? logicalName,
    String? status,
    String? ip,
  }) =>
      InterfaceModel(
        logicalName: logicalName ?? this.logicalName,
        realName: realName,
        status: status ?? this.status,
        ip: ip ?? this.ip,
      );

  factory InterfaceModel.fromJson(Map<String, dynamic> json) => InterfaceModel(
        logicalName: json['name'] ?? '', // ← name مش logicalName
        realName: json['name'] ?? '', // ← name مش realName
        status: json['status'] == 'up' // ← up/down مش connected/disconnected
            ? 'connected'
            : 'disconnected',
        ip: json['ip'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'logicalName': logicalName,
        'realName': realName,
        'status': status,
        'ip': ip,
      };
}
