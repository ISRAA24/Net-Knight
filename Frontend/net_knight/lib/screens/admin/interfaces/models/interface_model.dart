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
        logicalName: json['logicalName'] ?? json['name'] ?? '',
        realName: json['realName'] ?? json['name'] ?? '',
        status: json['status'] == 'up' ? 'connected' : 'disconnected',
        ip: json['ipAddress'] ?? json['ip'] ?? '',              // ← ipAddress
      );

  Map<String, dynamic> toJson() => {
        'logicalName': logicalName,
        'realName': realName,
        'status': status,
        'ip': ip,
      };
}