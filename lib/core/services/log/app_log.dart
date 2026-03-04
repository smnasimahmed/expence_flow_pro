import 'package:flutter/foundation.dart';

void appLog(dynamic message, {String source = 'App'}) {
  if (kDebugMode) debugPrint('[$source] $message');
}

void errorLog(dynamic error, {String source = 'Error'}) {
  if (kDebugMode) debugPrint('[$source] ❌ $error');
}
