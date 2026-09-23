import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../services/native_bridge.dart';

class DeviceInfoUtil {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Returns a **device-unique** fingerprint + a human-readable model name.
  ///
  /// The fingerprint is `Settings.Secure.ANDROID_ID`, fetched via our own
  /// method channel — NOT `AndroidDeviceInfo.id`, which is `Build.ID`
  /// (OS build number) and is the SAME across every phone running the
  /// same Android version.
  static Future<Map<String, String>> getAndroidDeviceInfo() async {
    if (!Platform.isAndroid) {
      return {'deviceId': 'non_android_test_device', 'model': 'Simulator'};
    }

    String androidId = '';
    try {
      androidId = await NativeBridge.getAndroidId();
    } catch (_) {}

    String model = 'Android Device';
    try {
      final AndroidDeviceInfo info = await _deviceInfoPlugin.androidInfo;
      model = '${info.manufacturer} ${info.model}';
    } catch (_) {}

    return {
      'deviceId': androidId.isNotEmpty ? androidId : 'unknown_android_id',
      'model': model,
    };
  }
}
