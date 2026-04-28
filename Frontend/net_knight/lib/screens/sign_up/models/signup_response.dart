class SignupResponse {
  final String message;

  SignupResponse({required this.message});

  factory SignupResponse.fromJson(Map<String, dynamic> json) =>
      SignupResponse(message: json['message']);
}
