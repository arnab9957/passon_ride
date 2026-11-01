// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:async';
import 'dart:js_util' as js_util;

Future<bool> sendGoogleSheetViaBrowser(String url, String jsonBody) async {
  final completer = Completer<bool>();

  try {
    js_util.callMethod(
      js_util.globalThis,
      'sendGoogleSheetWebhook',
      [
        url,
        jsonBody,
        js_util.allowInterop((Object? success) {
          if (!completer.isCompleted) {
            completer.complete(success == true);
          }
        }),
      ],
    );

    // Timeout safety fallback of 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(true); // mode: 'no-cors' usually succeeds silently
      }
    });
  } catch (e) {
    if (!completer.isCompleted) {
      completer.complete(false);
    }
  }

  return completer.future;
}
