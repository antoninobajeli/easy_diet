import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static String? _version;

  static Future<String> getVersion() async {
    if (_version != null) return _version!;
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _version = packageInfo.version;
      return _version!;
    } catch (e) {
      return '1.0.0';
    }
  }
}
