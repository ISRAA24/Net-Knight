class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String login;
  final String password; 

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.login,
    this.password = '',
  });


  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? login,
    String? password,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        login: login ?? this.login,
        password: password ?? this.password,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['username'] ?? json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'Analyst',
        login: json['lastLogin'] ?? 'N/A',
        password: json['password'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'username': name,
        'email': email,
        'role': role,
      };
}