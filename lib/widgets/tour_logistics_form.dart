import 'package:flutter/material.dart';

import '../models/tour_logistics.dart';

/// Form sections for the details an agency needs to publish a guided tour.
class TourLogisticsForm extends StatefulWidget {
  static const transportIcons = {
    'AC Bus / Volvo': Icons.directions_bus_filled,
    'Mini Bus': Icons.airport_shuttle,
    'Tempo Traveller': Icons.airport_shuttle_outlined,
    'SUV (Innova / Ertiga)': Icons.directions_car_filled,
    'Small Car (Hatchback / Sedan)': Icons.directions_car,
    'Jeep / 4x4': Icons.terrain,
    'Motorcycle': Icons.two_wheeler,
    'Scooty': Icons.electric_moped,
    'Bicycle': Icons.pedal_bike,
    'Train': Icons.train,
    'Boat / Ferry': Icons.directions_boat,
    'Flight': Icons.flight,
    'Trek / On Foot': Icons.hiking,
  };
  final TourLogistics initial;
  final ValueChanged<TourLogistics> onChanged;

  const TourLogisticsForm({super.key, required this.initial, required this.onChanged});

  @override
  State<TourLogisticsForm> createState() => _TourLogisticsFormState();
}

class _TourLogisticsFormState extends State<TourLogisticsForm> {
  late TourLogistics _v;
  late final _transportDetails = TextEditingController(text: widget.initial.transportDetails);
  late final _meetingPoint = TextEditingController(text: widget.initial.meetingPoint);
  late final _childPrice =
      TextEditingController(text: widget.initial.childPrice > 0 ? widget.initial.childPrice.toStringAsFixed(0) : '');
  late final _thingsToCarry = TextEditingController(text: widget.initial.thingsToCarry);
  late final _emergency = TextEditingController(text: widget.initial.emergencyContact);
  late final _license = TextEditingController(text: widget.initial.licenseNumber);
  final _exclusion = TextEditingController();

  @override
  void initState() {
    super.initState();
    _v = widget.initial;
  }

  @override
  void didUpdateWidget(TourLogisticsForm old) {
    super.didUpdateWidget(old);
    // Parent loaded an existing tour / AI draft after first build.
    if (!identical(old.initial, widget.initial) && widget.initial != _v) {
      _v = widget.initial;
      _transportDetails.text = _v.transportDetails;
      _meetingPoint.text = _v.meetingPoint;
      _childPrice.text = _v.childPrice > 0 ? _v.childPrice.toStringAsFixed(0) : '';
      _thingsToCarry.text = _v.thingsToCarry;
      _emergency.text = _v.emergencyContact;
      _license.text = _v.licenseNumber;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _transportDetails, _meetingPoint, _childPrice, _thingsToCarry, _emergency, _license, _exclusion
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(TourLogistics v) {
    setState(() => _v = v);
    widget.onChanged(v);
  }

  List<String> _toggle(List<String> list, String item) =>
      list.contains(item) ? (List.of(list)..remove(item)) : [...list, item];


  Widget _section(BuildContext context, IconData icon, Color color, String title, String hint, List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ]),
        const SizedBox(height: 6),
        Text(hint, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
      );

  Widget _chips(List<String> options, List<String> selected, ValueChanged<String> onTap, {Map<String, IconData>? icons}) =>
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final o in options)
          FilterChip(
            avatar: icons?[o] == null ? null : Icon(icons![o], size: 16),
            label: Text(o, style: const TextStyle(fontSize: 12)),
            selected: selected.contains(o),
            onSelected: (_) => onTap(o),
          ),
      ]);

  Widget _counter(String label, int value, int min, int max, ValueChanged<int> onChanged) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          Row(children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ]),
        ]),
      );


  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ---------------- TRANSPORT ----------------
      _section(context, Icons.commute, Colors.indigo, 'Transport Medium *',
          'How will travellers move during the tour? Select all that apply.', [
        _chips(TourLogistics.transportOptions, _v.transportModes,
            (o) => _set(_v.copyWith(transportModes: _toggle(_v.transportModes, o))),
            icons: TourLogisticsForm.transportIcons),
        const SizedBox(height: 12),
        TextField(
          controller: _transportDetails,
          onChanged: (t) => _set(_v.copyWith(transportDetails: t)),
          decoration: const InputDecoration(
            labelText: 'Vehicle details (optional)',
            hintText: 'e.g. 2 × AC Tempo Traveller, 12 seats each',
            prefixIcon: Icon(Icons.info_outline),
            isDense: true,
          ),
        ),
        Row(children: [
          Expanded(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Fuel & tolls included'),
              value: _v.fuelIncluded,
              onChanged: (b) => _set(_v.copyWith(fuelIncluded: b)),
            ),
          ),
          Expanded(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Driver included'),
              value: _v.driverIncluded,
              onChanged: (b) => _set(_v.copyWith(driverIncluded: b)),
            ),
          ),
        ]),
      ]),

      // ---------------- GROUP & SCHEDULE ----------------
      _section(context, Icons.groups, Colors.deepOrange, 'Group Size, Schedule & Meeting Point',
          'Travellers need to know when and where to show up.', [
        Row(children: [
          _counter('Min group', _v.minGroupSize, 1, _v.maxGroupSize,
              (n) => _set(_v.copyWith(minGroupSize: n))),
          _counter('Max group', _v.maxGroupSize, _v.minGroupSize, 100,
              (n) => _set(_v.copyWith(maxGroupSize: n))),
          _counter('Min age', _v.minAge, 0, 70, (n) => _set(_v.copyWith(minAge: n))),
        ]),
        _label('Difficulty level'),
        Wrap(spacing: 6, children: [
          for (final d in TourLogistics.difficultyOptions)
            ChoiceChip(
              label: Text(d),
              selected: _v.difficulty == d,
              onSelected: (_) => _set(_v.copyWith(difficulty: d)),
            ),
        ]),
        _label('Repeats on (for recurring tours; none = on request)'),
        _chips(TourLogistics.dayOptions, _v.departureDays,
            (o) => _set(_v.copyWith(
                departureDays: TourLogistics.dayOptions
                    .where(_toggle(_v.departureDays, o).contains)
                    .toList()))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _meetingPoint,
              onChanged: (t) => _set(_v.copyWith(meetingPoint: t)),
              decoration: const InputDecoration(
                labelText: 'Meeting / pickup point *',
                hintText: 'e.g. Siliguri Junction, Gate 1',
                prefixIcon: Icon(Icons.place_outlined),
                isDense: true,
              ),
            ),
          ),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Hotel pickup & drop available'),
          value: _v.hotelPickup,
          onChanged: (b) => _set(_v.copyWith(hotelPickup: b)),
        ),
      ]),

      // ---------------- STAY, MEALS, LANGUAGES ----------------
      _section(context, Icons.restaurant, Colors.green, 'Stay, Meals & Languages',
          'What is covered in the price, and which languages the guide speaks.', [
        _label('Accommodation'),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final a in TourLogistics.stayOptions)
            ChoiceChip(
              label: Text(a, style: const TextStyle(fontSize: 12)),
              selected: _v.accommodation == a,
              onSelected: (_) => _set(_v.copyWith(accommodation: a)),
            ),
        ]),
        _label('Meals included'),
        _chips(TourLogistics.mealOptions, _v.meals, (o) => _set(_v.copyWith(meals: _toggle(_v.meals, o)))),
        _label('Guide languages'),
        _chips(TourLogistics.languageOptions, _v.languages,
            (o) => _set(_v.copyWith(languages: _toggle(_v.languages, o)))),
        _label('Not included (exclusions)'),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final e in _v.exclusions)
            InputChip(
              label: Text(e, style: const TextStyle(fontSize: 12)),
              onDeleted: () => _set(_v.copyWith(exclusions: List.of(_v.exclusions)..remove(e))),
            ),
          for (final p in ['Personal expenses', 'Entry tickets', 'Camera fees', 'Travel insurance', 'Tips'])
            if (!_v.exclusions.contains(p))
              ActionChip(
                avatar: const Icon(Icons.add, size: 14),
                label: Text(p, style: const TextStyle(fontSize: 11)),
                onPressed: () => _set(_v.copyWith(exclusions: [..._v.exclusions, p])),
              ),
        ]),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _exclusion,
              decoration: const InputDecoration(hintText: 'Add other exclusion', isDense: true),
            ),
          ),
          TextButton(
            onPressed: () {
              final t = _exclusion.text.trim();
              if (t.isEmpty || _v.exclusions.contains(t)) return;
              _exclusion.clear();
              _set(_v.copyWith(exclusions: [..._v.exclusions, t]));
            },
            child: const Text('Add'),
          ),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _thingsToCarry,
          maxLines: 2,
          onChanged: (t) => _set(_v.copyWith(thingsToCarry: t)),
          decoration: const InputDecoration(
            labelText: 'Things to carry',
            hintText: 'e.g. Govt ID, warm jacket, sunscreen, power bank',
            prefixIcon: Icon(Icons.backpack_outlined),
            isDense: true,
          ),
        ),
      ]),

      // ---------------- POLICIES & COMPLIANCE ----------------
      _section(context, Icons.policy, Colors.purple, 'Pricing, Policies & Compliance',
          'Builds trust with travellers and is needed for agency verification.', [
        TextField(
          controller: _childPrice,
          keyboardType: TextInputType.number,
          onChanged: (t) => _set(_v.copyWith(childPrice: double.tryParse(t.trim()) ?? 0)),
          decoration: const InputDecoration(
            labelText: 'Child price (₹, below 12 yrs) — leave empty if same',
            prefixIcon: Icon(Icons.child_care),
            isDense: true,
          ),
        ),
        _label('Cancellation policy'),
        RadioGroup<String>(
          groupValue: _v.cancellationPolicy,
          onChanged: (p) => _set(_v.copyWith(cancellationPolicy: p)),
          child: Column(children: [
            for (final p in TourLogistics.cancellationOptions)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: p,
                title: Text(p, style: const TextStyle(fontSize: 12.5)),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emergency,
          keyboardType: TextInputType.phone,
          onChanged: (t) => _set(_v.copyWith(emergencyContact: t)),
          decoration: const InputDecoration(
            labelText: 'Emergency contact number *',
            prefixIcon: Icon(Icons.local_phone_outlined),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _license,
          onChanged: (t) => _set(_v.copyWith(licenseNumber: t)),
          decoration: const InputDecoration(
            labelText: 'Tourism / agency registration no. (optional)',
            hintText: 'e.g. State Tourism Dept. reg. or GSTIN',
            prefixIcon: Icon(Icons.verified_outlined),
            isDense: true,
          ),
        ),
      ]),
    ]);
  }
}
