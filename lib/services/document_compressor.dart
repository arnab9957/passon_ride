import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Shrinks photos and scans to JPEG under [maxKb], lowering quality before resolution
/// so that text stays readable. Returns null if the bytes are not a decodable image.
Future<Uint8List?> compressDocumentImage(Uint8List bytes, {int maxKb = 480}) {
  return compute(_compress, (bytes, maxKb));
}

Uint8List? _compress((Uint8List, int) input) {
  final (bytes, maxKb) = input;
  var image = img.decodeImage(bytes);
  if (image == null) return null;
  image = img.bakeOrientation(image);

  Uint8List? best;
  for (final width in const [2000, 1600, 1280, 1000]) {
    final sized = image.width > width ? img.copyResize(image, width: width) : image;
    for (final quality in const [85, 75, 65, 55]) {
      best = img.encodeJpg(sized, quality: quality);
      if (best.lengthInBytes <= maxKb * 1024) return best;
    }
  }
  return best;
}
