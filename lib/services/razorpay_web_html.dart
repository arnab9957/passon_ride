// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:convert';
import 'dart:js_util' as js_util;

void openWebRazorpayCheckout({
  required String key,
  required String orderId,
  required int amount,
  required String name,
  required String description,
  required String contact,
  required String email,
  Map<String, dynamic>? notes,
  required Function(String paymentId, String orderId, String signature) onSuccess,
  required Function(String errorMsg) onError,
}) {
  final String notesJson = notes != null ? jsonEncode(notes) : '{}';

  js_util.callMethod(
    js_util.globalThis,
    'openRazorpayCheckout',
    [
      key,
      orderId,
      amount,
      name,
      description,
      contact,
      email,
      notesJson,
      js_util.allowInterop((Object? payId, Object? ordId, Object? sig) {
        onSuccess(payId?.toString() ?? '', ordId?.toString() ?? '', sig?.toString() ?? '');
      }),
      js_util.allowInterop((Object? errorMsg) {
        onError(errorMsg?.toString() ?? 'Cancelled');
      }),
    ],
  );
}
