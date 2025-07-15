class NoSmtpPasswordException implements Exception {
  String errMsg() => 'Password in SMTP credentials is missing';
}