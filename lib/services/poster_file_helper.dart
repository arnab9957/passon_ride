import 'dart:typed_data';

import 'poster_file_helper_stub.dart'
    if (dart.library.js_interop) 'poster_file_helper_web.dart' as impl;

/// Whether the browser/OS can share image files (always true off-web).
bool canShareImageFile(Uint8List bytes, String name) => impl.canShareImageFile(bytes, name);

/// Saves [bytes] as a download (web only; no-op elsewhere).
void downloadFile(Uint8List bytes, String name, {String mime = 'image/png'}) =>
    impl.downloadFile(bytes, name, mime: mime);
