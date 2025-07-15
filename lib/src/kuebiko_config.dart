import 'package:version/version.dart';

class KuebikoConfig {
  final String appName;
  final Version appVersion;
  final Uri baseUrl;
  final String? apiKey;
  final String deviceName;
  final Version libraryVersion = Version(1, 0, 0);
  final String apiVersion = '1';

  KuebikoConfig({
    required this.appName,
    required this.appVersion,
    required this.baseUrl,
    required this.deviceName,
    this.apiKey
  });

  Uri generateApiUri(String endpoint, {Map<String, dynamic>? queryParameters}){

    if(queryParameters == null){
      queryParameters = {
        'version': apiVersion
      };
    } else {
      queryParameters['version'] = apiVersion;
    }

    String scheme;
    if (this.baseUrl.scheme.isNotEmpty && (this.baseUrl.scheme == 'http' || this.baseUrl.scheme == 'https')) {
      scheme = this.baseUrl.scheme;
    } else {
      scheme = 'https';
    }

    return Uri(
        scheme: scheme,
        host: this.baseUrl.host,
        path: this.baseUrl.pathSegments.join('/') + '/' + 'v' + apiVersion + endpoint,
        port: this.baseUrl.port,
        queryParameters: queryParameters
    );
  }
}