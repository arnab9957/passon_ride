import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class ImageKitAuthParams {
  final String token;
  final int expire;
  final String signature;

  ImageKitAuthParams({
    required this.token,
    required this.expire,
    required this.signature,
  });
}

class ImageKitService {
  final String publicKey;
  final String privateKey;
  final String urlEndpoint;

  ImageKitService({
    this.publicKey = 'public_nsJbsDdm19m9BgCAOv2UMbpy/HI=',
    this.privateKey = 'private_5/fwszcSPz24H6XDv/4V3gyiUk0=',
    this.urlEndpoint = 'https://ik.imagekit.io/hsqoovxu0',
  });

  /// Generate client-side authentication parameters (token, expire, signature) using HMAC-SHA1
  ImageKitAuthParams getAuthParameters() {
    final token = 'token_${DateTime.now().millisecondsSinceEpoch}';
    final expire = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 2400; // 40 minutes expiration
    final pKey = privateKey.isNotEmpty ? privateKey : 'private_5/fwszcSPz24H6XDv/4V3gyiUk0=';
    final key = utf8.encode(pKey);
    final bytesToSign = utf8.encode('$token$expire');

    final hmacSha1 = Hmac(sha1, key);
    final digest = hmacSha1.convert(bytesToSign);
    final signature = digest.toString();

    return ImageKitAuthParams(
      token: token,
      expire: expire,
      signature: signature,
    );
  }

  /// Construct ImageKit CDN URL with real-time image transformations (e.g. /tr:w-800,h-600,c-at_max/)
  String buildImageUrl(
    String imagePathOrUrl, {
    int? width,
    int? height,
    List<String>? transformations,
  }) {
    if (imagePathOrUrl.startsWith('data:') || imagePathOrUrl.isEmpty) {
      return imagePathOrUrl;
    }

    final trList = <String>[];
    if (width != null) trList.add('w-$width');
    if (height != null) trList.add('h-$height');
    if (transformations != null) trList.addAll(transformations);

    if (trList.isEmpty) return imagePathOrUrl;

    final trParam = 'tr:${trList.join(',')}';

    if (imagePathOrUrl.startsWith('http')) {
      final uri = Uri.tryParse(imagePathOrUrl);
      if (uri != null && urlEndpoint.isNotEmpty && imagePathOrUrl.contains(urlEndpoint)) {
        final path = uri.path;
        return '$urlEndpoint/$trParam$path';
      }
      return imagePathOrUrl;
    }

    final cleanPath = imagePathOrUrl.startsWith('/') ? imagePathOrUrl : '/$imagePathOrUrl';
    final endpoint = urlEndpoint.isNotEmpty ? urlEndpoint : 'https://ik.imagekit.io/hsqoovxu0';
    return '$endpoint/$trParam$cleanPath';
  }

  /// Upload raw image bytes to ImageKit.io CDN using signed multipart upload
  Future<String?> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String folder = '/vehicles',
  }) async {
    try {
      final base64File = base64Encode(bytes);
      final uri = Uri.parse('https://upload.imagekit.io/api/v1/files/upload');
      final request = http.MultipartRequest('POST', uri);

      final pKey = privateKey.isNotEmpty ? privateKey : 'private_5/fwszcSPz24H6XDv/4V3gyiUk0=';
      final pubKey = publicKey.isNotEmpty ? publicKey : 'public_nsJbsDdm19m9BgCAOv2UMbpy/HI=';

      final authParams = getAuthParameters();
      request.fields['publicKey'] = pubKey;
      request.fields['signature'] = authParams.signature;
      request.fields['expire'] = authParams.expire.toString();
      request.fields['token'] = authParams.token;

      final authHeader = 'Basic ${base64Encode(utf8.encode('$pKey:'))}';
      request.headers['Authorization'] = authHeader;

      request.fields['file'] = 'data:image/jpeg;base64,$base64File';
      request.fields['fileName'] = fileName;
      request.fields['useUniqueFileName'] = 'true';
      request.fields['folder'] = folder;

      final streamedResponse = await request.send().timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      } else {
        print('ImageKit upload HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ImageKitService upload error: $e');
      return null;
    }
  }

  /// Upload base64 data string to ImageKit.io CDN
  Future<String?> uploadBase64({
    required String base64String,
    required String fileName,
    String folder = '/vehicles',
  }) async {
    try {
      final uri = Uri.parse('https://upload.imagekit.io/api/v1/files/upload');
      final request = http.MultipartRequest('POST', uri);

      final pKey = privateKey.isNotEmpty ? privateKey : 'private_5/fwszcSPz24H6XDv/4V3gyiUk0=';
      final pubKey = publicKey.isNotEmpty ? publicKey : 'public_nsJbsDdm19m9BgCAOv2UMbpy/HI=';

      final authParams = getAuthParameters();
      request.fields['publicKey'] = pubKey;
      request.fields['signature'] = authParams.signature;
      request.fields['expire'] = authParams.expire.toString();
      request.fields['token'] = authParams.token;

      final authHeader = 'Basic ${base64Encode(utf8.encode('$pKey:'))}';
      request.headers['Authorization'] = authHeader;

      request.fields['file'] = base64String.startsWith('data:')
          ? base64String
          : 'data:image/jpeg;base64,$base64String';
      request.fields['fileName'] = fileName;
      request.fields['useUniqueFileName'] = 'true';
      request.fields['folder'] = folder;

      final streamedResponse = await request.send().timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      } else {
        print('ImageKit upload HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ImageKitService uploadBase64 error: $e');
      return null;
    }
  }
}
