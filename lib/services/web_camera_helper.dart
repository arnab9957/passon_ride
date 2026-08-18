import 'dart:typed_data';
import 'package:flutter/widgets.dart';

import 'web_camera_helper_stub.dart'
    if (dart.library.html) 'web_camera_helper_web.dart' as impl;

abstract class WebCameraManager {
  static bool get isSupported => impl.isWebCameraSupported();

  static Widget buildLiveCameraView({
    required String viewId,
    required double width,
    required double height,
    required VoidCallback onInitialized,
    required Function(String error) onError,
  }) => impl.buildLiveCameraView(
    viewId: viewId,
    width: width,
    height: height,
    onInitialized: onInitialized,
    onError: onError,
  );

  static Future<Uint8List?> captureFrame(String viewId) =>
      impl.captureFrame(viewId);

  static void stopCamera(String viewId) => impl.stopCamera(viewId);
}
