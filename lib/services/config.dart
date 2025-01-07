import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String supabaseUrl = _getSupabaseUrl();
  static String supabaseAnon = _getSupabaseAnon();

  static String _getSupabaseUrl() {
    if (kReleaseMode) {
      return const String.fromEnvironment('supabaseurl', defaultValue: '');
    } else {
      return dotenv.env['supabaseurl'] ?? '';
    }
  }

  static String _getSupabaseAnon() {
    if (kReleaseMode) {
      return const String.fromEnvironment('supabaseanon', defaultValue: '');
    } else {
      return dotenv.env['supabaseanon'] ?? '';
    }
  }
}
