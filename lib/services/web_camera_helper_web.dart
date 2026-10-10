// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final Map<String, html.VideoElement> _activeVideoElements = {};
final Map<String, html.MediaStream> _activeStreams = {};
final Set<String> _registeredViewIds = {};

bool isWebCameraSupported() {
  try {
    return html.window.navigator.mediaDevices != null;
  } catch (_) {
    return false;
  }
}

Widget buildLiveCameraView({
  required String viewId,
  required double width,
  required double height,
  required VoidCallback onInitialized,
  required Function(String error) onError,
}) {
  if (!_registeredViewIds.contains(viewId)) {
    _registeredViewIds.add(viewId);
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'; // Mirror for front selfie

      _activeVideoElements[viewId] = videoElement;

      void attachStream(dynamic constraints) {
        html.window.navigator.mediaDevices?.getUserMedia(constraints).then((stream) {
          _activeStreams[viewId] = stream;
          videoElement.srcObject = stream;
          videoElement.play();
          onInitialized();
        }).catchError((err) {
          // If constrained facingMode failed, retry with simple video: true
          if (constraints is Map && constraints['video'] is Map) {
            attachStream({'video': true, 'audio': false});
          } else {
            onError(err.toString());
          }
        });
      }

      attachStream({
        'video': {
          'facingMode': 'user',
        },
        'audio': false,
      });

      return videoElement;
    });
  }

  return HtmlElementView(viewType: viewId);
}

Future<Uint8List?> captureFrame(String viewId) async {
  try {
    final video = _activeVideoElements[viewId];
    if (video == null) return null;

    // Wait until video has frame metadata loaded
    int retries = 0;
    while ((video.videoWidth == 0 || video.readyState < 2) && retries < 12) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    final width = video.videoWidth > 0 ? video.videoWidth : 640;
    final height = video.videoHeight > 0 ? video.videoHeight : 480;

    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;

    ctx.translate(width, 0);
    ctx.scale(-1, 1);
    ctx.drawImage(video, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    final commaIndex = dataUrl.indexOf(',');
    final base64String = commaIndex != -1 ? dataUrl.substring(commaIndex + 1) : dataUrl;
    if (base64String.isNotEmpty) {
      return base64Decode(base64String);
    }
    return null;
  } catch (e) {
    debugPrint('Web camera captureFrame error: $e');
    return null;
  }
}

void stopCamera(String viewId) {
  _registeredViewIds.remove(viewId);
  final stream = _activeStreams.remove(viewId);
  stream?.getTracks().forEach((track) => track.stop());

  final video = _activeVideoElements.remove(viewId);
  video?.pause();
  video?.srcObject = null;
}
