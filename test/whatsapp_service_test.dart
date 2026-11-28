// WhatsApp Click-to-Chat: phone normalisation, wa.me links, message templates,
// and the "could not open" result that drives the copy-message fallback.
import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/services/whatsapp_service.dart';

Booking _booking({String status = 'Pending', String phone = '+91 98300-12345'}) => Booking(
      id: 'b_1700000000000',
      bookingReference: 'PR-7KQ2M9XA',
      vehicleId: 'veh_activa',
      vehicleTitle: 'Honda Activa 6G',
      vehicleImageUrl: '',
      hostName: 'Blue Wave Rentals',
      userId: 'rider_1',
      hostId: 'host_1',
      // 10:00 and 18:30 IST, stored as UTC like the database does
      startDate: DateTime.utc(2031, 1, 10, 4, 30),
      endDate: DateTime.utc(2031, 1, 11, 13, 0),
      totalPrice: 1250,
      status: status,
      unlockPasscode: 'PASS-1234',
      createdAt: DateTime.utc(2031, 1, 1),
      customerName: 'Rina Das',
      customerPhone: phone,
      pickupLocation: 'Hill Cart Road, Siliguri',
      rejectionReason: '',
    );

void main() {
  group('normalizePhone', () {
    test('Indian mobile numbers get country code 91, no plus sign', () {
      expect(WhatsAppService.normalizePhone('98300 12345'), '919830012345');
      expect(WhatsAppService.normalizePhone('+91 98300-12345'), '919830012345');
      expect(WhatsAppService.normalizePhone('(+91) 98300 12345'), '919830012345');
      expect(WhatsAppService.normalizePhone('098300 12345'), '919830012345');
      expect(WhatsAppService.normalizePhone('0091 9830012345'), '919830012345');
    });

    test('international numbers keep their own country code', () {
      expect(WhatsAppService.normalizePhone('+44 7911 123456'), '447911123456');
      expect(WhatsAppService.normalizePhone('+1 (415) 555-0132'), '14155550132');
    });

    test('missing or invalid numbers are rejected, never replaced', () {
      for (final bad in [null, '', '   ', '12345', '0123456789', '+91 12345 67890', '+91 98765 43210', '1234567890123456']) {
        expect(WhatsAppService.normalizePhone(bad), isNull, reason: '"$bad"');
      }
    });
  });

  test('wa.me link URL-encodes the whole message', () {
    final uri = WhatsAppService.buildUri('919830012345', 'Booking ID: PR-1\nAmount: ₹1,250 & more?');
    expect(uri.toString(), startsWith('https://wa.me/919830012345?text='));
    expect(uri.toString(), isNot(contains(' ')));
    expect(uri.toString(), isNot(contains('\n')));
    expect(uri.queryParameters['text'], 'Booking ID: PR-1\nAmount: ₹1,250 & more?');
  });

  group('templates use the booking row', () {
    test('A. new request for the owner', () {
      final m = WhatsAppService.newRequestForOwner(_booking());
      expect(m, contains('Booking ID: PR-7KQ2M9XA'));
      expect(m, contains('Renter Name: Rina Das'));
      expect(m, contains('Renter Contact: +91 98300-12345'));
      expect(m, contains('Vehicle: Honda Activa 6G'));
      expect(m, contains('Pickup Date: 10 Jan 2031'));
      expect(m, contains('Pickup Time: 10:00 AM'));
      expect(m, contains('Return Date: 11 Jan 2031'));
      expect(m, contains('Return Time: 6:30 PM'));
      expect(m, contains('Pickup Location: Hill Cart Road, Siliguri'));
      expect(m, contains('Estimated Rental Amount: ₹1,250'));
      expect(m, contains('Status: PENDING APPROVAL'));
    });

    test('B. confirmation for the renter includes the owner contact', () {
      final m = WhatsAppService.confirmationForRenter(_booking(status: 'Confirmed'), ownerPhone: '+91 98000 11111');
      expect(m, contains('Your PassionRide booking is confirmed!'));
      expect(m, contains('Owner: Blue Wave Rentals'));
      expect(m, contains('Owner Contact: +91 98000 11111'));
      expect(m, contains('Total Rental Amount: ₹1,250'));
      expect(m, contains('Status: CONFIRMED'));
    });

    test('C. confirmation for the owner', () {
      final m = WhatsAppService.confirmationForOwner(_booking(status: 'Confirmed'));
      expect(m, contains('Pickup: 10 Jan 2031, 10:00 AM'));
      expect(m, contains('Return: 11 Jan 2031, 6:30 PM'));
      expect(m, contains('Please prepare the vehicle'));
    });

    test('D. rejection for the renter', () {
      final m = WhatsAppService.rejectionForRenter(_booking(status: 'Rejected'));
      expect(m, contains('could not be confirmed'));
      expect(m, contains('Status: REJECTED'));
      expect(m, isNot(contains('Rina')), reason: 'no need to repeat personal data');
    });

    test('no identity-document data ever goes into a message', () {
      final b = _booking();
      for (final m in [
        WhatsAppService.newRequestForOwner(b),
        WhatsAppService.confirmationForOwner(b),
        WhatsAppService.confirmationForRenter(b, ownerPhone: ''),
        WhatsAppService.rejectionForRenter(b),
        WhatsAppService.cancellation(b),
      ]) {
        expect(m.toLowerCase(), isNot(contains('licen')));
        expect(m.toLowerCase(), isNot(contains('aadhaar')));
        expect(m, isNot(contains('PASS-1234')), reason: 'unlock PIN stays in the app');
      }
    });

    test('the message matches the status', () {
      expect(WhatsAppService.messageForOwner(_booking(status: 'Pending')), contains('PENDING APPROVAL'));
      expect(WhatsAppService.messageForOwner(_booking(status: 'Confirmed')), contains('has been confirmed'));
      expect(WhatsAppService.messageForRenter(_booking(status: 'Pending'), ownerPhone: ''), isNull,
          reason: 'nothing to notify the renter about until the owner decides');
      expect(WhatsAppService.messageForRenter(_booking(status: 'Rejected'), ownerPhone: ''), contains('REJECTED'));
      expect(WhatsAppService.messageForRenter(_booking(status: 'Active'), ownerPhone: ''), contains('CONFIRMED'));
      expect(WhatsAppService.messageForOwner(_booking(status: 'Completed')), isNull);
    });

    test('Indian digit grouping for amounts', () {
      expect(WhatsAppService.formatAmount(950), '950');
      expect(WhatsAppService.formatAmount(1250), '1,250');
      expect(WhatsAppService.formatAmount(123456), '1,23,456');
      expect(WhatsAppService.formatAmount(1234.5), '1,234.50');
    });
  });

  group('open()', () {
    test('opens wa.me with the pre-filled message', () async {
      Uri? opened;
      final svc = WhatsAppService(launcher: (u) async {
        opened = u;
        return true;
      });
      final r = await svc.shareBookingWithOwner(_booking(), ownerPhone: '98000 11111');
      expect(r, WhatsAppOpenResult.opened);
      expect(opened!.host, 'wa.me');
      expect(opened!.path, '/919800011111');
      expect(opened!.queryParameters['text'], contains('PR-7KQ2M9XA'));
    });

    test('invalid phone: WhatsApp is not opened', () async {
      var called = false;
      final svc = WhatsAppService(launcher: (_) async => called = true);
      expect(await svc.shareBookingWithOwner(_booking(), ownerPhone: ''), WhatsAppOpenResult.invalidPhone);
      expect(called, isFalse);
    });

    test('WhatsApp unavailable (launch refused or throws) is reported, not swallowed', () async {
      expect(await WhatsAppService(launcher: (_) async => false).shareBookingRejection(_booking(status: 'Rejected')),
          WhatsAppOpenResult.unavailable);
      expect(await WhatsAppService(launcher: (_) async => throw Exception('no handler'))
              .shareBookingRejection(_booking(status: 'Rejected')),
          WhatsAppOpenResult.unavailable);
    });
  });
}
