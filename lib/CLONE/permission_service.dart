// services/permission_service.dart

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAllPermissions() async {
    if (Platform.isIOS) {
      await Permission.bluetooth.request();
    }
    await Permission.camera.request();
    await Permission.locationWhenInUse.request();
  }
}
