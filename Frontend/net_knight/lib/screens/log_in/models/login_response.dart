class LoginResponse {
  final String message;
  final String email;

  LoginResponse({required this.message, required this.email});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        message: json['message'] ?? '',
        email: json['email'] ?? '',
      );
}
