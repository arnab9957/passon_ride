import 'dart:typed_data';
import 'package:flutter/widgets.dart';

bool isWebCameraSupported() => false;

Widget buildLiveCameraView({
  required String viewId,
  required double width,
  required double height,
  required VoidCallback onInitialized,
  required Function(String error) onError,
}) {
  return const SizedBox.shrink();
}

Future<Uint8List?> captureFrame(String viewId) async => null;

void stopCamera(String viewId) {}
