class FormatNotAllowedException implements Exception {
  final String format;
  String errMsg() => "The format "+this.format+" isnt allowed";
  FormatNotAllowedException(this.format);
}