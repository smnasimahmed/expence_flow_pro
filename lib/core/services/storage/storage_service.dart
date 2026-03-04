import 'package:get_storage/get_storage.dart';
import '../../constants/app_strings.dart';

// One place to read/write local storage.
// Every key is in AppKeys so nothing is hardcoded outside this file.
class StorageService {
  StorageService._();
  static final _box = GetStorage();

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static bool get rememberMe => _box.read(AppKeys.rememberMe) ?? false;
  static set rememberMe(bool v) => _box.write(AppKeys.rememberMe, v);

  static String get userId => _box.read(AppKeys.userId) ?? '';
  static set userId(String v) => _box.write(AppKeys.userId, v);

  static String get userEmail => _box.read(AppKeys.userEmail) ?? '';
  static set userEmail(String v) => _box.write(AppKeys.userEmail, v);

  static String get userName => _box.read(AppKeys.userName) ?? '';
  static set userName(String v) => _box.write(AppKeys.userName, v);

  // ─── Sync ─────────────────────────────────────────────────────────────────
  static DateTime? get lastSyncTime {
    final ms = _box.read<int>(AppKeys.lastSyncTime);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static set lastSyncTime(DateTime? v) {
    if (v == null) return;
    _box.write(AppKeys.lastSyncTime, v.millisecondsSinceEpoch);
  }

  // ─── Settings ─────────────────────────────────────────────────────────────
  static bool get biometricEnabled => _box.read(AppKeys.biometricEnabled) ?? false;
  static set biometricEnabled(bool v) => _box.write(AppKeys.biometricEnabled, v);

  static String get currency => _box.read(AppKeys.currency) ?? 'USD';
  static set currency(String v) => _box.write(AppKeys.currency, v);

  // ─── Clear all on logout ──────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _box.erase();
  }
}
