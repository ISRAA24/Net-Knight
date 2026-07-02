class ThreatData {
  final String ip;
  final String type;
  final String level;
  final String confidence;
  final String time;

  const ThreatData({
    required this.ip,
    required this.type,
    required this.level,
    required this.confidence,
    required this.time,
  });
}
