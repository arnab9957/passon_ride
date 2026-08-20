import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/services/stream_chat_service.dart';

class AllowRealNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  HttpOverrides.global = AllowRealNetworkHttpOverrides();

  group('Stream Chat SDK Integration Tests', () {
    final streamService = StreamChatService();
    const testApiKey = 'rb3gvmquantv';
    const testApiSecret = '8mgwnv4pkn23aewxspjw4nxpbpgur7bh2xj99srx4cw87ggwab6etaebc32fccnn';

    tearDown(() async {
      await streamService.disconnectUser();
    });

    test('1. StreamChatService initializes client with valid API Key', () async {
      final client = await streamService.init(apiKey: testApiKey, apiSecret: testApiSecret);

      expect(client, isNotNull);
      expect(streamService.isInitialized, isTrue);
      expect(streamService.apiKey, equals(testApiKey));
    });

    test('2. StreamChatService connects User with authentic JWT Token', () async {
      await streamService.init(apiKey: testApiKey, apiSecret: testApiSecret);

      final ownUser = await streamService.connectDevUser(
        userId: 'test_rider_101',
        name: 'Test Rider',
        image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        extraData: {'role': 'Rider'},
      );

      expect(ownUser, isNotNull);
      expect(ownUser?.id, equals('test_rider_101'));
      expect(ownUser?.name, equals('Test Rider'));
      expect(streamService.isConnected, isTrue);
    });

    test('3. StreamChatService creates and watches a Messaging Channel', () async {
      await streamService.init(apiKey: testApiKey, apiSecret: testApiSecret);

      await streamService.connectDevUser(
        userId: 'test_rider_101',
        name: 'Test Rider',
      );

      final channel = await streamService.getOrCreateChannel(
        channelId: 'booking_test_channel_101',
        memberIds: ['test_rider_101'],
        channelName: 'Royal Enfield Rental Chat',
        extraData: {
          'vehicleTitle': 'Royal Enfield Classic 350',
          'bookingId': 'BK101',
        },
      );

      expect(channel, isNotNull);
      expect(channel.id, equals('booking_test_channel_101'));
      expect(channel.name, equals('Royal Enfield Rental Chat'));
    });
  });
}
