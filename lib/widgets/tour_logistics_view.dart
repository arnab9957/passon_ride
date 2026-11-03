import 'package:flutter/material.dart';

import '../models/tour_logistics.dart';
import 'tour_logistics_form.dart';

/// Customer-facing summary of a tour's logistics (transport, group, meeting point, policies).
class TourLogisticsView extends StatelessWidget {
  final TourLogistics logistics;
  const TourLogisticsView({super.key, required this.logistics});

  static String _daysNights(int days) {
    final d = '$days day${days == 1 ? '' : 's'}';
    if (days < 2) return d;
    final n = days - 1;
    return '$d / $n night${n == 1 ? '' : 's'}';
  }

  static Widget _dateCol(String label, DateTime d, String time, {bool alignEnd = false}) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
      Text('${w[d.weekday - 1]}, ${d.day} ${m[d.month - 1]} ${d.year}',
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
      if (time.isNotEmpty) Text(time, style: const TextStyle(fontSize: 12)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = logistics;
    if (l.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        );

    Widget fact(IconData icon, String label, String value) => Container(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        );

    Widget row(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 16, color: color ?? scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35))),
          ]),
        );

    final days = l.departureDays.isEmpty
        ? 'On request'
        : (l.departureDays.length == 7 ? 'Daily' : l.departureDays.join(', '));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (l.transportModes.isNotEmpty) ...[
        heading('🚌 Transport'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in l.transportModes)
            Chip(
              avatar: Icon(TourLogisticsForm.transportIcons[m] ?? Icons.commute, size: 16),
              label: Text(m, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              visualDensity: VisualDensity.compact,
            ),
        ]),
        if (l.transportDetails.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l.transportDetails, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          ),
        const SizedBox(height: 4),
        Text(
          [
            if (l.driverIncluded) '✓ Driver included',
            if (l.fuelIncluded) '✓ Fuel & tolls included',
          ].join('   '),
          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
        ),
      ],
      if (l.tourStartDate != null) ...[
        heading('🗓️ Tour dates'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Expanded(child: _dateCol('Starts', l.tourStartDate!, l.startTime)),
            Icon(Icons.arrow_forward, color: scheme.primary),
            Expanded(child: _dateCol('Ends', l.tourEndDate ?? l.tourStartDate!, l.endTime, alignEnd: true)),
          ]),
        ),
        if (l.tourDays != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_daysNights(l.tourDays!),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.primary)),
          ),
      ],
      heading('📋 Tour essentials'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        fact(Icons.groups, 'Group size', '${l.minGroupSize}–${l.maxGroupSize} people'),
        fact(Icons.trending_up, 'Difficulty', l.difficulty),
        if (l.tourStartDate == null || l.departureDays.isNotEmpty) fact(Icons.event, 'Departs', days),
        if (l.tourStartDate == null && l.startTime.isNotEmpty)
          fact(Icons.schedule, 'Timing', l.endTime.isEmpty ? l.startTime : '${l.startTime} – ${l.endTime}'),
        if (l.minAge > 0) fact(Icons.cake_outlined, 'Min age', '${l.minAge}+ years'),
        fact(Icons.hotel, 'Stay', l.accommodation),
        if (l.languages.isNotEmpty) fact(Icons.translate, 'Languages', l.languages.join(', ')),
        if (l.childPrice > 0) fact(Icons.child_care, 'Child price', '₹${l.childPrice.toStringAsFixed(0)}'),
      ]),
      if (l.meetingPoint.isNotEmpty) ...[
        heading('📍 Meeting point'),
        row(Icons.place, l.meetingPoint, color: Colors.redAccent),
        if (l.hotelPickup) row(Icons.local_taxi, 'Hotel pickup & drop available', color: Colors.green),
      ],
      if (l.meals.isNotEmpty) ...[
        heading('🍽️ Meals included'),
        Text(l.meals.join(' • '), style: const TextStyle(fontSize: 13)),
      ],
      if (l.exclusions.isNotEmpty) ...[
        heading('❌ Not included'),
        for (final e in l.exclusions) row(Icons.remove_circle_outline, e, color: Colors.redAccent),
      ],
      if (l.thingsToCarry.isNotEmpty) ...[
        heading('🎒 Things to carry'),
        Text(l.thingsToCarry, style: const TextStyle(fontSize: 13, height: 1.4)),
      ],
      heading('🛡️ Policies'),
      row(Icons.event_busy, 'Cancellation: ${l.cancellationPolicy}'),
      if (l.emergencyContact.isNotEmpty) row(Icons.local_phone, 'Emergency contact: ${l.emergencyContact}'),
      if (l.licenseNumber.isNotEmpty)
        row(Icons.verified, 'Registered agency • ${l.licenseNumber}', color: Colors.green),
      const SizedBox(height: 16),
    ]);
  }
}
