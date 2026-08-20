import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

/// Dedicated service for managing Stream Chat Flutter SDK connection and channels
class StreamChatService {
  static final StreamChatService _instance = StreamChatService._internal();
  factory StreamChatService() => _instance;
  StreamChatService._internal();

  /// Stream Chat Client instance
  stream.StreamChatClient? _client;

  /// Active Stream Chat Client
  stream.StreamChatClient? get client => _client;

  /// Current Stream Credentials
  String _apiKey = 'rb3gvmquantv';
  String _apiSecret = '8mgwnv4pkn23aewxspjw4nxpbpgur7bh2xj99srx4cw87ggwab6etaebc32fccnn';

  String get apiKey => _apiKey;
  String get apiSecret => _apiSecret;

  /// Whether client is initialized and connected
  bool get isInitialized => _client != null;
  bool get isConnected => _client?.state.currentUser != null;

  /// Generate a valid HMAC-SHA256 JWT token for Stream Chat authentication
  String generateToken(String userId) {
    final sanitizedUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final headerMap = {'alg': 'HS256', 'typ': 'JWT'};
    final payloadMap = {'user_id': sanitizedUserId};

    final header = base64Url.encode(utf8.encode(jsonEncode(headerMap))).replaceAll('=', '');
    final payload = base64Url.encode(utf8.encode(jsonEncode(payloadMap))).replaceAll('=', '');
    final message = '$header.$payload';

    final hmac = Hmac(sha256, utf8.encode(_apiSecret));
    final signature = base64Url.encode(hmac.convert(utf8.encode(message)).bytes).replaceAll('=', '');

    return '$message.$signature';
  }

  /// Initialize StreamChatClient with the provided API Key & Secret
  Future<stream.StreamChatClient> init({String? apiKey, String? apiSecret}) async {
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKey = apiKey;
    }
    if (apiSecret != null && apiSecret.isNotEmpty) {
      _apiSecret = apiSecret;
    }

    if (_client == null) {
      _client = stream.StreamChatClient(
        _apiKey,
        logLevel: kDebugMode ? stream.Level.INFO : stream.Level.OFF,
      );
      debugPrint('StreamChatClient initialized (API Key: $_apiKey)');
    }

    return _client!;
  }

  /// Connect user with authentic JWT token
  Future<stream.OwnUser?> connectDevUser({
    required String userId,
    String? name,
    String? image,
    Map<String, dynamic>? extraData,
  }) async {
    final clientInstance = _client ?? await init();
    final sanitizedUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    if (isConnected && clientInstance.state.currentUser?.id == sanitizedUserId) {
      debugPrint('Stream Chat user $sanitizedUserId already connected');
      return clientInstance.state.currentUser;
    }

    final token = generateToken(sanitizedUserId);

    final streamUser = stream.User(
      id: sanitizedUserId,
      name: name ?? sanitizedUserId,
      image: image ?? 'https://getstream.io/random_png/?name=${Uri.encodeComponent(name ?? sanitizedUserId)}',
      extraData: extraData ?? {},
    );

    try {
      debugPrint('Connecting to Stream Chat for user: $sanitizedUserId');
      final ownUser = await clientInstance.connectUser(streamUser, token);
      debugPrint('Stream Chat connected successfully for ${ownUser.name} (${ownUser.id})');
      return ownUser;
    } catch (e) {
      if (e.toString().contains('Connection already available')) {
        return clientInstance.state.currentUser;
      }
      debugPrint('Stream Chat connect error: $e. Retrying with fallback token.');
      try {
        final devToken = clientInstance.devToken(sanitizedUserId);
        return await clientInstance.connectUser(streamUser, devToken.rawValue);
      } catch (devErr) {
        debugPrint('Stream Chat dev fallback error: $devErr');
        rethrow;
      }
    }
  }

  /// Disconnect the active Stream user
  Future<void> disconnectUser() async {
    if (_client != null && isConnected) {
      await _client!.disconnectUser();
      debugPrint('Stream Chat user disconnected');
    }
  }

  /// Create or watch a Stream Messaging Channel for a P2P rental thread
  Future<stream.Channel> getOrCreateChannel({
    required String channelId,
    String channelType = 'messaging',
    required List<String> memberIds,
    String? channelName,
    String? channelImage,
    Map<String, dynamic>? extraData,
  }) async {
    final clientInstance = _client ?? await init();

    final sanitizedId = channelId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final sanitizedMembers = memberIds.map((id) => id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')).toList();

    final channelData = <String, dynamic>{
      if (channelName != null) 'name': channelName,
      if (channelImage != null) 'image': channelImage,
      'members': sanitizedMembers,
      if (extraData != null) ...extraData,
    };

    try {
      final channel = clientInstance.channel(
        channelType,
        id: sanitizedId,
        extraData: channelData,
      );
      await channel.watch();
      return channel;
    } catch (e) {
      if (e.toString().contains("don't exist")) {
        debugPrint('Stream Chat channel notice: Uncreated member IDs detected. Retrying channel creation without strict member constraint.');
        final fallbackData = <String, dynamic>{
          if (channelName != null) 'name': channelName,
          if (channelImage != null) 'image': channelImage,
          if (extraData != null) ...extraData,
        };
        final channel = clientInstance.channel(
          channelType,
          id: sanitizedId,
          extraData: fallbackData,
        );
        await channel.watch();
        return channel;
      }
      rethrow;
    }
  }
}
