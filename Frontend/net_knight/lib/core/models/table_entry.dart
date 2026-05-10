class TableEntry {
  final String name;
  final String family;

  const TableEntry({required this.name, required this.family});

  factory TableEntry.fromJson(Map<String, dynamic> json) => TableEntry(
        name: json['name'] ?? '',
        family: json['family'] ?? 'ip',
      );
}
