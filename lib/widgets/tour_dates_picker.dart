import 'package:flutter/material.dart';

import '../models/tour_logistics.dart';

/// Start → end date range plus start/end time for a tour.
class TourDatesPicker extends StatelessWidget {
  final TourLogistics logistics;
  final ValueChanged<TourLogistics> onChanged;

  const TourDatesPicker({super.key, required this.logistics, required this.onChanged});

  static String fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${w[d.weekday - 1]}, ${d.day} ${m[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDates(BuildContext context) async {
    final now = DateTime.now();
    final l = logistics;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
      initialDateRange: (l.tourStartDate != null && l.tourEndDate != null && !l.tourStartDate!.isBefore(DateTime(now.year, now.month, now.day)))
          ? DateTimeRange(start: l.tourStartDate!, end: l.tourEndDate!)
          : null,
      helpText: 'Select tour start & end date',
      saveText: 'Done',
    );
    if (range == null) return;
    onChanged(l.copyWith(tourStartDate: range.start, tourEndDate: range.end));
  }

  Future<void> _pickTime(BuildContext context, {required bool end}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: end ? 18 : 7, minute: 0),
      helpText: end ? 'Tour end time' : 'Tour start time',
    );
    if (t == null || !context.mounted) return;
    final text = t.format(context);
    onChanged(end ? logistics.copyWith(endTime: text) : logistics.copyWith(startTime: text));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = logistics;
    final hasDates = l.tourStartDate != null;

    Widget box({
      required IconData icon,
      required String label,
      required String value,
      required VoidCallback onTap,
      bool empty = false,
    }) =>
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: empty ? scheme.outlineVariant : scheme.primary.withValues(alpha: 0.6)),
              ),
              child: Row(children: [
                Icon(icon, size: 20, color: empty ? scheme.onSurfaceVariant : scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: empty ? scheme.onSurfaceVariant : scheme.onSurface,
                        )),
                  ]),
                ),
              ]),
            ),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(
          child: Text('Tour Start & End:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        if (hasDates)
          TextButton.icon(
            onPressed: () => onChanged(l.withoutDates()),
            icon: const Icon(Icons.close, size: 14),
            label: const Text('Clear dates', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        box(
          icon: Icons.flight_takeoff,
          label: 'Starts on',
          value: hasDates ? fmt(l.tourStartDate!) : 'Select date',
          empty: !hasDates,
          onTap: () => _pickDates(context),
        ),
        const SizedBox(width: 8),
        box(
          icon: Icons.flight_land,
          label: 'Ends on',
          value: hasDates ? fmt(l.tourEndDate ?? l.tourStartDate!) : 'Select date',
          empty: !hasDates,
          onTap: () => _pickDates(context),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        box(
          icon: Icons.schedule,
          label: 'Start time',
          value: l.startTime.isEmpty ? 'Set time' : l.startTime,
          empty: l.startTime.isEmpty,
          onTap: () => _pickTime(context, end: false),
        ),
        const SizedBox(width: 8),
        box(
          icon: Icons.flag_outlined,
          label: 'End time',
          value: l.endTime.isEmpty ? 'Set time' : l.endTime,
          empty: l.endTime.isEmpty,
          onTap: () => _pickTime(context, end: true),
        ),
      ]),
      const SizedBox(height: 6),
      Text(
        hasDates
            ? '🗓️ ${l.tourDays} day${l.tourDays == 1 ? '' : 's'} tour — duration and "Valid Until" are filled in from these dates.'
            : 'Leave dates empty for a recurring tour and choose "Repeats on" days below.',
        style: TextStyle(fontSize: 11.5, color: hasDates ? scheme.primary : scheme.onSurfaceVariant),
      ),
    ]);
  }
}
