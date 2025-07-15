# Kuebiko Dart API Client Library

Usage:

```dart
import 'package:kuebiko_client/kuebiko_client.dart';

main(){
  
  // With API Key
  KuebikoConfig config = KuebikoConfig(
      appName: 'Demo App',
      appVersion: Version(1, 0, 0),
      baseUrl: Uri.parse('https://demo.kuebiko.app'),
      deviceName: 'demo Device',
      apiKey: 'someApiKey'
  );

  KuebikoClient client = KuebikoClient(config);
  
  // Without API Key
  KuebikoConfig config = KuebikoConfig(
      appName: 'Demo App',
      appVersion: Version(1, 0, 0),
      baseUrl: Uri.parse('https://demo.kuebiko.app'),
      deviceName: 'demo Device',
  );

  KuebikoClient client = KuebikoClient.login(config, 'username', 'password');
}
```