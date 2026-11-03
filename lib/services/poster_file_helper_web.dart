import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

web.File _file(Uint8List bytes, String name, String mime) =>
    web.File([bytes.toJS].toJS, name, web.FilePropertyBag(type: mime));

bool canShareImageFile(Uint8List bytes, String name) {
  try {
    final data = web.ShareData(files: [_file(bytes, name, 'image/png')].toJS);
    return web.window.navigator.canShare(data);
  } catch (_) {
    return false;
  }
}

void downloadFile(Uint8List bytes, String name, {String mime = 'image/png'}) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body?.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}
