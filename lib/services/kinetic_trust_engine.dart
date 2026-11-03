import 'dart:math' as math;

import '../models/models.dart';

/// One booking's contribution to the renter's Kinetic Trust Score.
class TrustEvent {
  final Booking booking;
  final String kind; // completed | cancelled | no_show | upcoming | host_cancelled
  final String label;
  final double recencyWeight; // w = 2^(-age/180d)
  final double? punctuality; // s_i in [0,1] for completed rides with timing data
  final double penalty; // weighted penalty fed into reliability
  final String detail;

  const TrustEvent({
    required this.booking,
    required this.kind,
    required this.label,
    required this.recencyWeight,
    required this.punctuality,
    required this.penalty,
    required this.detail,
  });
}

/// Result of [KineticTrustEngine.evaluate]: overall score plus every component,
/// so the UI can show exactly how the number was produced.
class KineticTrustReport {
  final double score; // 0..100
  final double reliability; // R
  final double punctuality; // P
  final double verification; // V
  final double experience; // E
  final int totalBookings;
  final int completed;
  final int customerCancellations;
  final int lastMinuteCancellations;
  final int noShows;
  final int hostCancellations;
  final double avgLateReturnMinutes;
  final double cancellationRate;
  final List<TrustEvent> events;
  final List<String> badges;

  const KineticTrustReport({
    required this.score,
    required this.reliability,
    required this.punctuality,
    required this.verification,
    required this.experience,
    required this.totalBookings,
    required this.completed,
    required this.customerCancellations,
    required this.lastMinuteCancellations,
    required this.noShows,
    required this.hostCancellations,
    required this.avgLateReturnMinutes,
    required this.cancellationRate,
    required this.events,
    required this.badges,
  });

  String get tier {
    if (score >= 90) return 'Platinum Rider';
    if (score >= 75) return 'Gold Rider';
    if (score >= 60) return 'Silver Rider';
    if (score >= 40) return 'Bronze Rider';
    return 'At Risk';
  }
}

/// Kinetic Trust Score for renters, computed from their own booking lifecycle
/// (book → pick up → return, or cancel / no-show) plus KYC documents.
///
///   S = 100 · (0.40·R + 0.25·P + 0.20·V + 0.15·E)
///
/// R  Reliability   Bayesian-smoothed completion ratio, recency-weighted:
///                  R = (Σw·[completed] + α·p₀) / (Σw·[completed] + Σw·c(h) + Σw·1.5·[no-show] + α)
///                  c(h) = e^(−h/24) cancellation cost for h hours of notice (h ≤ 0 → 1)
/// P  Punctuality   P = (Σw·sᵢ + β·p₀) / (Σw + β),
///                  sᵢ = e^(−late_return_min/120) · e^(−late_pickup_min/240)
/// V  Verification  0.6·[DL verified & valid] (0.3 if pending) + 0.4·[Aadhaar on file]
/// E  Experience    E = 1 − e^(−completed/5)
/// w  Recency       w = 2^(−age_days/180)  (half-life 180 days)
class KineticTrustEngine {
  static const double wReliability = 0.40;
  static const double wPunctuality = 0.25;
  static const double wVerification = 0.20;
  static const double wExperience = 0.15;

  static const double priorMean = 0.85; // p₀
  static const double alpha = 3; // reliability prior strength (pseudo-rides)
  static const double beta = 2; // punctuality prior strength
  static const double halfLifeDays = 180;
  static const double cancelDecayHours = 24;
  static const double noShowWeight = 1.5;
  static const double lateReturnScaleMin = 120;
  static const double latePickupScaleMin = 240;
  static const Duration pickupGrace = Duration(minutes: 15);
  static const Duration noShowGrace = Duration(hours: 2);
  static const double experienceScale = 5;

  static double recencyWeight(DateTime when, DateTime now) {
    final ageDays = math.max(0, now.difference(when).inMinutes / 1440.0);
    return math.pow(2, -ageDays / halfLifeDays).toDouble();
  }

  /// Cost of a renter cancellation given hours of notice before the start time.
  static double cancellationCost(double hoursNotice) =>
      hoursNotice <= 0 ? 1.0 : math.exp(-hoursNotice / cancelDecayHours);

  static double punctualityOf({required double lateReturnMin, required double latePickupMin}) =>
      math.exp(-math.max(0, lateReturnMin) / lateReturnScaleMin) *
      math.exp(-math.max(0, latePickupMin) / latePickupScaleMin);

  static KineticTrustReport evaluate({
    required List<Booking> bookings,
    required List<ComplianceDocument> documents,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final events = <TrustEvent>[];

    double good = 0, bad = 0;
    double punctSum = 0, punctWeight = 0;
    double lateSum = 0;
    int lateCount = 0;
    int completed = 0, custCancels = 0, lastMinute = 0, noShows = 0, hostCancels = 0;

    for (final b in bookings) {
      final status = b.status.toLowerCase();
      final w = recencyWeight(b.endDate.isBefore(t) ? b.endDate : b.createdAt, t);

      if (status == 'cancelled') {
        if (b.cancelledBy == 'host') {
          hostCancels++;
          events.add(TrustEvent(
            booking: b,
            kind: 'host_cancelled',
            label: 'Cancelled by host',
            recencyWeight: w,
            punctuality: null,
            penalty: 0,
            detail: 'No impact — not your fault',
          ));
          continue;
        }
        final cancelledAt = b.cancelledAt ?? b.rentalEndedAt ?? b.createdAt;
        final hours = b.startDate.difference(cancelledAt).inMinutes / 60.0;
        final cost = cancellationCost(hours);
        final cw = recencyWeight(cancelledAt, t);
        bad += cw * cost;
        custCancels++;
        if (hours < 24) lastMinute++;
        events.add(TrustEvent(
          booking: b,
          kind: 'cancelled',
          label: hours <= 0 ? 'Cancelled after start' : 'Cancelled ${_fmtNotice(hours)} before start',
          recencyWeight: cw,
          punctuality: null,
          penalty: cw * cost,
          detail: 'Penalty c(h)=${cost.toStringAsFixed(2)} × w=${cw.toStringAsFixed(2)}',
        ));
        continue;
      }

      if (status == 'completed') {
        completed++;
        good += w;
        double? s;
        String detail = 'Completed — return time not tracked';
        // Real timing data only when the ride was actually started & ended by the app.
        if (b.rentalStartedAt != null && b.rentalEndedAt != null) {
          final lateReturn = b.rentalEndedAt!.difference(b.endDate).inMinutes.toDouble();
          final latePickup =
              b.rentalStartedAt!.difference(b.startDate.add(pickupGrace)).inMinutes.toDouble();
          s = punctualityOf(lateReturnMin: lateReturn, latePickupMin: latePickup);
          punctSum += w * s;
          punctWeight += w;
          lateSum += math.max(0, lateReturn);
          lateCount++;
          detail = lateReturn > 0
              ? 'Returned ${lateReturn.round()} min late · s=${s.toStringAsFixed(2)}'
              : 'Returned on time · s=${s.toStringAsFixed(2)}';
        }
        events.add(TrustEvent(
          booking: b,
          kind: 'completed',
          label: 'Ride completed',
          recencyWeight: w,
          punctuality: s,
          penalty: 0,
          detail: detail,
        ));
        continue;
      }

      // Confirmed but never picked up well after the start → no-show.
      if (status == 'confirmed' && b.rentalStartedAt == null && t.isAfter(b.startDate.add(noShowGrace))) {
        final nw = recencyWeight(b.startDate, t);
        bad += nw * noShowWeight;
        noShows++;
        events.add(TrustEvent(
          booking: b,
          kind: 'no_show',
          label: 'No-show',
          recencyWeight: nw,
          punctuality: null,
          penalty: nw * noShowWeight,
          detail: 'Not picked up within 2 h of start · penalty $noShowWeight× w',
        ));
        continue;
      }

      events.add(TrustEvent(
        booking: b,
        kind: 'upcoming',
        label: status == 'active' ? 'Ride in progress' : 'Upcoming ride',
        recencyWeight: w,
        punctuality: null,
        penalty: 0,
        detail: 'Counts once it is completed',
      ));
    }

    final reliability = (good + alpha * priorMean) / (good + bad + alpha);
    final punctuality = (punctSum + beta * priorMean) / (punctWeight + beta);
    final verification = _verification(documents);
    final experience = 1 - math.exp(-completed / experienceScale);

    final raw = 100 *
        (wReliability * reliability +
            wPunctuality * punctuality +
            wVerification * verification +
            wExperience * experience);
    final score = (raw.clamp(0, 100) * 10).round() / 10;

    final decided = completed + custCancels + noShows;
    final badges = <String>[
      if (_dlState(documents) == 2) 'License Verified',
      if (_hasAadhaar(documents)) 'ID Verified',
      if (completed >= 1) 'First Ride',
      if (completed >= 10) '10+ Rides',
      if (completed >= 50) '50+ Rides',
      if (completed >= 3 && custCancels == 0 && noShows == 0) 'Zero Cancellations',
      if (lateCount >= 3 && punctuality >= 0.95) 'Always On Time',
    ];

    events.sort((a, b) => b.booking.startDate.compareTo(a.booking.startDate));

    return KineticTrustReport(
      score: score,
      reliability: reliability,
      punctuality: punctuality,
      verification: verification,
      experience: experience,
      totalBookings: bookings.length,
      completed: completed,
      customerCancellations: custCancels,
      lastMinuteCancellations: lastMinute,
      noShows: noShows,
      hostCancellations: hostCancels,
      avgLateReturnMinutes: lateCount == 0 ? 0 : lateSum / lateCount,
      cancellationRate: decided == 0 ? 0 : (custCancels + noShows) / decided,
      events: events,
      badges: badges,
    );
  }

  /// 0 = none, 1 = uploaded/pending, 2 = verified & not expired.
  static int _dlState(List<ComplianceDocument> docs) {
    final dl = docs.where((d) => '${d.type} ${d.title}'.toLowerCase().contains('license'));
    if (dl.any((d) => d.status.toLowerCase().contains('verified') && d.isExpiryValid)) return 2;
    if (dl.any((d) => d.isExpiryValid && !d.status.toLowerCase().contains('reject'))) return 1;
    return 0;
  }

  static bool _hasAadhaar(List<ComplianceDocument> docs) => docs.any((d) {
        final label = '${d.type} ${d.title}'.toLowerCase();
        return label.contains('aadha') && !d.status.toLowerCase().contains('reject');
      });

  static double _verification(List<ComplianceDocument> docs) {
    final dl = _dlState(docs);
    return (dl == 2 ? 0.6 : (dl == 1 ? 0.3 : 0.0)) + (_hasAadhaar(docs) ? 0.4 : 0.0);
  }

  static String _fmtNotice(double hours) {
    if (hours < 1) return '${(hours * 60).round()} min';
    if (hours < 48) return '${hours.round()} h';
    return '${(hours / 24).round()} days';
  }
}
