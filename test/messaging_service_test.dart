import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/services/platform_leakage_filter.dart';
import 'package:passon_ride/services/transactional_notification_service.dart';
import 'package:passon_ride/models/models.dart';

void main() {
  group('Platform Leakage Content Moderation Filter Tests', () {
    test('1. Normal safe conversation text should NOT be flagged', () {
      const input = 'Hi, is the bike available for pickup tomorrow at 10 AM?';
      final result = PlatformLeakageFilter.scanAndSanitize(input);

      expect(result.isFlagged, isFalse);
      expect(result.sanitizedText, equals(input));
      expect(result.flaggedReasons, isEmpty);
      expect(result.riskScore, equals(0.0));
    });

    test('2. Standard 10-digit phone number sharing attempt SHOULD be masked', () {
      const input = 'Call me at 9876543210 to talk directly.';
      final result = PlatformLeakageFilter.scanAndSanitize(input);

      expect(result.isFlagged, isTrue);
      expect(result.sanitizedText, contains('[RESTRICTED: Contact info removed]'));
      expect(result.flaggedReasons, contains('Phone Number Sharing Attempt'));
      expect(result.riskScore, greaterThan(0.4));
    });

    test('3. Obfuscated spelled-out phone digits SHOULD be detected and masked', () {
      const input = 'My number is nine eight seven six five four three two one zero';
      final result = PlatformLeakageFilter.scanAndSanitize(input);

      expect(result.isFlagged, isTrue);
      expect(result.sanitizedText, contains('[RESTRICTED: Obfuscated contact info detected]'));
      expect(result.flaggedReasons, contains('Obfuscated Spelled-out Phone Number'));
    });

    test('4. Off-platform UPI handles and email addresses SHOULD be masked', () {
      const input = 'Send money to my email rider@gmail.com or UPI user@paytm directly';
      final result = PlatformLeakageFilter.scanAndSanitize(input);

      expect(result.isFlagged, isTrue);
      expect(result.sanitizedText, contains('[RESTRICTED: Email address removed]'));
      expect(result.sanitizedText, contains('[RESTRICTED: Off-platform payment handle removed]'));
      expect(result.flaggedReasons, contains('Direct Email Address Sharing'));
      expect(result.flaggedReasons, contains('Direct UPI/Off-platform Payment Handle'));
    });

    test('5. External WhatsApp/PayPal links and credit card digits SHOULD be masked', () {
      const input = 'Pay via https://paypal.me/user or card 4111111111111111 pay offline';
      final result = PlatformLeakageFilter.scanAndSanitize(input);

      expect(result.isFlagged, isTrue);
      expect(result.sanitizedText, contains('[RESTRICTED: External link removed]'));
      expect(result.sanitizedText, contains('[RESTRICTED: Card Number Masked]'));
      expect(result.flaggedReasons, contains('External Social / Communication Link'));
      expect(result.flaggedReasons, contains('Raw Card Number / Financial Data'));
    });
  });

  group('Four-Flow Transactional Notification Topology Tests', () {
    late TransactionalNotificationService notificationService;

    setUp(() {
      notificationService = TransactionalNotificationService();
    });

    test('Flow 1: Buyer Checkout SMS OTP triggers sub-12s latency verification', () async {
      final result = await notificationService.triggerBuyerCheckoutOtp(
        phoneNumber: '+919876543210',
        buyerName: 'Rahul Sharma',
        orderAmount: 1200.0,
      );

      expect(result.success, isTrue);
      expect(result.flowType, equals(NotificationFlowType.buyerCheckoutOtp));
      expect(result.channel, equals(NotificationChannel.sms));
      expect(result.otpCode, isNotNull);
      expect(result.otpCode!.length, equals(6));
      expect(result.status, equals('DELIVERED_SUB_12S'));
    });

    test('Flow 2: Seller KYC & Bank Payout alteration alerts trigger SMS notification', () async {
      final result = await notificationService.triggerSellerKycAlert(
        phoneNumber: '+919876543210',
        sellerName: 'Sovan Rajbanshi',
        alertType: 'BANK_PAYOUT_CHANGED',
        detailSummary: 'HDFC Bank ending in 4892',
      );

      expect(result.success, isTrue);
      expect(result.flowType, equals(NotificationFlowType.sellerKycAlert));
      expect(result.payloadText, contains('SECURITY ALERT'));
      expect(result.payloadText, contains('HDFC Bank ending in 4892'));
    });

    test('Flow 3: High-Value rentals (>= ₹15,000) trigger WhatsApp Step-Up OTP', () async {
      const highValueAmount = 18500.0;
      final isHighValue = notificationService.requiresHighValueStepUp(highValueAmount);

      expect(isHighValue, isTrue);

      final result = await notificationService.triggerHighValueStepUpWhatsAppOtp(
        phoneNumber: '+919876543210',
        userName: 'Priya Verma',
        rentalAmount: highValueAmount,
        vehicleTitle: 'Royal Enfield Himalayan 450',
      );

      expect(result.success, isTrue);
      expect(result.flowType, equals(NotificationFlowType.highValueWhatsappOtp));
      expect(result.channel, equals(NotificationChannel.whatsapp));
      expect(result.status, equals('DELIVERED_WHATSAPP_E2EE'));
      expect(result.payloadText, contains('IP Device Channel'));
    });

    test('Flow 4: Automated Booking Lifecycle Alerts trigger lifecycle messages', () async {
      final result = await notificationService.triggerBookingLifecycleAlert(
        phoneNumber: '+919876543210',
        renterName: 'Rider',
        vehicleTitle: 'Mahindra Thar 4x4',
        eventType: 'ESCROW_SECURED',
      );

      expect(result.success, isTrue);
      expect(result.flowType, equals(NotificationFlowType.bookingLifecycleAlert));
      expect(result.payloadText, contains('Escrow Protection Active'));
    });
  });

  group('P2P Messaging Model Moderation Integration Tests', () {
    test('ChatMessage deserializes and preserves moderation flags', () {
      final msg = ChatMessage.fromMap({
        'id': 'm_101',
        'sender_id': 'u_renter_1',
        'content': '[RESTRICTED: Contact info removed]',
        'is_moderated': true,
        'original_content': 'Call me at 9876543210',
        'flagged_reasons': ['Phone Number Sharing Attempt'],
      });

      expect(msg.id, equals('m_101'));
      expect(msg.isModerated, isTrue);
      expect(msg.originalContent, equals('Call me at 9876543210'));
      expect(msg.flaggedReasons, contains('Phone Number Sharing Attempt'));
    });
  });

  group('Real-Time WhatsApp-Style Chat Features Tests', () {
    test('ChatMessage lifecycle status ticks and message types', () {
      final msgSent = ChatMessage(
        id: 'msg_1',
        senderId: 'user_1',
        text: 'Hello owner!',
        timestamp: DateTime.now(),
        isUser: true,
        status: 'sent',
        messageType: 'text',
      );
      expect(msgSent.status, equals('sent'));
      expect(msgSent.messageType, equals('text'));

      final msgRead = msgSent.copyWith(status: 'read', isRead: true);
      expect(msgRead.status, equals('read'));
      expect(msgRead.isRead, isTrue);
    });

    test('ChatMessage rich attachment support for Image, Location & Document', () {
      final imgMsg = ChatMessage(
        id: 'msg_img',
        senderId: 'user_1',
        text: 'Photo',
        timestamp: DateTime.now(),
        isUser: true,
        messageType: 'image',
        attachmentUrl: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc',
      );
      expect(imgMsg.messageType, equals('image'));
      expect(imgMsg.attachmentUrl, isNotNull);

      final locMsg = ChatMessage(
        id: 'msg_loc',
        senderId: 'user_1',
        text: '📍 Pickup Coordinates',
        timestamp: DateTime.now(),
        isUser: true,
        messageType: 'location',
        latitude: 12.9716,
        longitude: 77.5946,
      );
      expect(locMsg.messageType, equals('location'));
      expect(locMsg.latitude, equals(12.9716));
      expect(locMsg.longitude, equals(77.5946));

      final docMsg = ChatMessage(
        id: 'msg_doc',
        senderId: 'user_1',
        text: '📄 Rental_Agreement.pdf',
        timestamp: DateTime.now(),
        isUser: true,
        messageType: 'document',
        attachmentUrl: 'https://passonride.com/docs/agreement.pdf',
      );
      expect(docMsg.messageType, equals('document'));
    });

    test('ChatThread links to Booking ID and tracks unread count', () {
      final thread = ChatThread(
        id: 'c_b_1024',
        partnerName: 'Vikram Singh',
        partnerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        lastMessage: 'Is the bike available tomorrow?',
        lastTime: DateTime.now(),
        unreadCount: 3,
        vehicleTitle: 'Royal Enfield Classic 350',
        messages: [],
        bookingId: 'BK1024',
        vehicleId: 'v102',
        renterId: 'r_101',
        providerId: 'p_202',
      );

      expect(thread.bookingId, equals('BK1024'));
      expect(thread.vehicleId, equals('v102'));
      expect(thread.unreadCount, equals(3));

      final readThread = thread.copyWith(unreadCount: 0);
      expect(readThread.unreadCount, equals(0));
    });
  });
}
