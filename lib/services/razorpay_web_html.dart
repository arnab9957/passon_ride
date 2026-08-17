// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:js_util' as js_util;

void openWebRazorpayCheckout(
  String key,
  int amount,
  String name,
  String description,
  String contact,
  String email,
  Function(String paymentId, String orderId, String signature) onSuccess,
  Function(String errorMsg) onError,
) {
  js_util.callMethod(
    js_util.globalThis,
    'openRazorpayCheckout',
    [
      key,
      amount,
      name,
      description,
      contact,
      email,
      js_util.allowInterop((Object? payId, Object? ordId, Object? sig) {
        onSuccess(payId?.toString() ?? '', ordId?.toString() ?? '', sig?.toString() ?? '');
      }),
      js_util.allowInterop((Object? errorMsg) {
        onError(errorMsg?.toString() ?? 'Cancelled');
      }),
    ],
  );
}
