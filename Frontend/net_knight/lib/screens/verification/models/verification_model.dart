class VerificationModel {
  final String maskedEmail;
  final int otpLength;

  const VerificationModel({
    required this.maskedEmail,
    required this.otpLength,
  });
}
