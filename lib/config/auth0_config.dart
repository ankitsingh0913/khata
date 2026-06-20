import 'package:flutter_dotenv/flutter_dotenv.dart';

class Auth0Config{
  static String get clientId {
    final value = dotenv.env['AUTH0_CLIENT_ID'];
    if (value == null || value.isEmpty) {
      throw StateError('Missing AUTH0_CLIENT_ID in environment');
    }
    return value;
  }
}