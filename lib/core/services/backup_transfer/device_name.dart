import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Best-effort human-readable name for this device, shown to the other side
/// during pairing (e.g. "Pixel 8" or "Lupus-Desktop"). Never throws — falls
/// back to the platform name if the plugin call fails.
Future<String> currentDeviceName() async {
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return '${android.manufacturer} ${android.model}'.trim();
    }
    if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return ios.name;
    }
    if (Platform.isWindows) {
      final windows = await info.windowsInfo;
      return windows.computerName.isNotEmpty
          ? windows.computerName
          : 'Windows-PC';
    }
    if (Platform.isLinux) {
      final linux = await info.linuxInfo;
      return linux.prettyName.isNotEmpty ? linux.prettyName : 'Linux-PC';
    }
  } catch (_) {
    // Fall through to the generic platform name below.
  }
  return currentPlatformName();
}

/// Short platform identifier sent alongside the device name (`android`,
/// `ios`, `windows`, `linux`) — used for display only, not protocol logic.
String currentPlatformName() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}
