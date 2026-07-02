class TableModel {
  final String name;
  final String family;

  const TableModel({required this.name, required this.family});

  Map<String, dynamic> toJson() => {
        'name': name,
        'family': family,
      };

  String toCommand() => 'nft add table $family $name';
}
