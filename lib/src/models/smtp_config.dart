class SmtpConfig {
  final Uri host;
  final int port;
  final String username;
  final String? password;
  final String encryption;

  SmtpConfig({
    required this.host,
    required this.port,
    required this.username,
    this.password,
    required this.encryption
  });
}