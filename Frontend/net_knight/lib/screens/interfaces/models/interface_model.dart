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
        logicalName: json['logicalName'] ?? '',
        realName: json['realName'] ?? '',
        status: json['status'] ?? 'disconnected',
        ip: json['ip'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'logicalName': logicalName,
        'realName': realName,
        'status': status,
        'ip': ip,
      };
}
