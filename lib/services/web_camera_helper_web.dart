// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final Map<String, html.VideoElement> _activeVideoElements = {};
final Map<String, html.MediaStream> _activeStreams = {};

bool isWebCameraSupported() => true;

Widget buildLiveCameraView({
  required String viewId,
  required double width,
  required double height,
  required VoidCallback onInitialized,
  required Function(String error) onError,
}) {
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

    html.window.navigator.mediaDevices?.getUserMedia({
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
      'audio': false,
    }).then((stream) {
      _activeStreams[viewId] = stream;
      videoElement.srcObject = stream;
      videoElement.play();
      onInitialized();
    }).catchError((err) {
      onError(err.toString());
    });

    return videoElement;
  });

  return HtmlElementView(viewType: viewId);
}

Future<Uint8List?> captureFrame(String viewId) async {
  final video = _activeVideoElements[viewId];
  if (video == null) return null;

  final width = video.videoWidth > 0 ? video.videoWidth : 640;
  final height = video.videoHeight > 0 ? video.videoHeight : 480;

  final canvas = html.CanvasElement(width: width, height: height);
  final ctx = canvas.context2D;

  ctx.translate(width, 0);
  ctx.scale(-1, 1);
  ctx.drawImage(video, 0, 0);

  final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
  final base64String = dataUrl.split(',').last;
  return base64Decode(base64String);
}

void stopCamera(String viewId) {
  final stream = _activeStreams.remove(viewId);
  stream?.getTracks().forEach((track) => track.stop());

  final video = _activeVideoElements.remove(viewId);
  video?.pause();
  video?.srcObject = null;
}
