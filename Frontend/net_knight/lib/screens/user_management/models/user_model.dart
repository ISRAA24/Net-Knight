class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String login;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.login,
  });

  String get initials =>
      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? login,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        login: login ?? this.login,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['username'] ?? json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'Analyst',
        login: json['lastLogin'] ?? 'N/A',
      );

  Map<String, dynamic> toJson() => {
        'username': name,
        'email': email,
        'role': role,
      };
}
