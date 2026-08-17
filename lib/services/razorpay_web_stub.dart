void openWebRazorpayCheckout(
  String key,
  int amount,
  String name,
  String description,
  String contact,
  String email,
  Function(String paymentId, String orderId, String signature) onSuccess,
  Function(String errorMsg) onError,
) {}
