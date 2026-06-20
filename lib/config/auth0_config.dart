import 'package:flutter_dotenv/flutter_dotenv.dart';

class Auth0Config{
  static final String clientId = dotenv.env['AUTH0_CLIENT_ID'] ?? '';
}