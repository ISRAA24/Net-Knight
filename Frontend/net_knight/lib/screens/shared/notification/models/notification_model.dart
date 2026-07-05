class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final String type; // threat, rule, system, etc.
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? false,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      description: description,
      time: time,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}