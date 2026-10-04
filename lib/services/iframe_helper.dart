import 'iframe_helper_stub.dart'
    if (dart.library.html) 'iframe_helper_web.dart' as impl;

void registerIframeElement({
  required String viewType,
  required String url,
  String allow = '',
  bool allowFullscreen = false,
}) {
  impl.registerIframeElement(
    viewType: viewType,
    url: url,
    allow: allow,
    allowFullscreen: allowFullscreen,
  );
}
