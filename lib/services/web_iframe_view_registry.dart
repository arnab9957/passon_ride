import 'web_iframe_view_registry_stub.dart'
    if (dart.library.html) 'web_iframe_view_registry_web.dart' as impl;

void registerIframeViewFactory({
  required String viewType,
  required String url,
}) {
  impl.registerIframeViewFactory(viewType: viewType, url: url);
}
