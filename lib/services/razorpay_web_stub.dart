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
}) {}
