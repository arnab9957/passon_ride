import 'package:flutter/material.dart';

import '../models/price_component.dart';

/// Lets a provider add their own price lines (fees, add-ons, deposits, discounts)
/// that appear in the customer's checkout breakdown.
class PriceComponentsEditor extends StatelessWidget {
  final List<PriceComponent> components;
  final ValueChanged<List<PriceComponent>> onChanged;
  final String baseLabel; // e.g. "Rental charge" / "Tour price"
  final double basePrice;
  final bool allowPerPerson;

  const PriceComponentsEditor({
    super.key,
    required this.components,
    required this.onChanged,
    required this.baseLabel,
    required this.basePrice,
    this.allowPerPerson = false,
  });

  static const _vehicleSuggestions = <(String, PriceKind, PriceUnit)>[
    ('Security deposit', PriceKind.deposit, PriceUnit.perBooking),
    ('Helmet', PriceKind.charge, PriceUnit.perDay),
    ('Extra helmet (pillion)', PriceKind.charge, PriceUnit.perDay),
    ('Riding gear (jacket, gloves)', PriceKind.charge, PriceUnit.perDay),
    ('Knee & elbow guards', PriceKind.charge, PriceUnit.perDay),
    ('Saddle bags / luggage rack', PriceKind.charge, PriceUnit.perDay),
    ('Phone holder', PriceKind.charge, PriceUnit.perBooking),
    ('Rain cover / raincoat', PriceKind.charge, PriceUnit.perBooking),
    ('Fuel (full tank)', PriceKind.charge, PriceUnit.perBooking),
    ('Insurance', PriceKind.charge, PriceUnit.perDay),
    ('Delivery / pickup', PriceKind.charge, PriceUnit.perBooking),
    ('Cleaning fee', PriceKind.charge, PriceUnit.perBooking),
    ('GST', PriceKind.charge, PriceUnit.perBooking),
    ('Early-bird discount', PriceKind.discount, PriceUnit.perBooking),
  ];

  static const _tourSuggestions = <(String, PriceKind, PriceUnit)>[
    ('Security deposit', PriceKind.deposit, PriceUnit.perPerson),
    ('Helmet', PriceKind.charge, PriceUnit.perPerson),
    ('Riding / trekking gear', PriceKind.charge, PriceUnit.perPerson),
    ('Camping gear (tent, sleeping bag)', PriceKind.charge, PriceUnit.perPerson),
    ('Meals', PriceKind.charge, PriceUnit.perPerson),
    ('Entry / permit fees', PriceKind.charge, PriceUnit.perPerson),
    ('Accommodation', PriceKind.charge, PriceUnit.perPerson),
    ('Transport', PriceKind.charge, PriceUnit.perPerson),
    ('Insurance', PriceKind.charge, PriceUnit.perPerson),
    ('Photography package', PriceKind.charge, PriceUnit.perBooking),
    ('GST', PriceKind.charge, PriceUnit.perBooking),
    ('Group discount', PriceKind.discount, PriceUnit.perBooking),
  ];

  List<(String, PriceKind, PriceUnit)> get _suggestions => allowPerPerson ? _tourSuggestions : _vehicleSuggestions;

  void _edit(BuildContext context, {int? index, PriceComponent? preset}) async {
    final existing = index != null ? components[index] : preset;
    final result = await showDialog<PriceComponent>(
      context: context,
      builder: (_) => _PriceLineDialog(initial: existing, allowPerPerson: allowPerPerson),
    );
    if (result == null) return;
    final next = [...components];
    if (index != null) {
      next[index] = result;
    } else {
      next.add(result);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = PriceBreakdown.build(baseLabel: baseLabel, base: basePrice, components: components);
    String rs(double v) => '₹${v.abs().toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Price breakdown shown at checkout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          TextButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ]),
        Text('Add your own charges, add-ons, deposits or discounts. Customers see each line separately.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        const SizedBox(height: 4),
        const Text('Quick add — tap, set the price, save:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Wrap(spacing: 6, runSpacing: 4, children: [
          for (final (label, kind, unit) in _suggestions)
            if (!components.any((c) => c.label.toLowerCase() == label.toLowerCase()))
              ActionChip(
                label: Text('+ $label', style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                onPressed: () => _edit(context, preset: PriceComponent(label: label, amount: 0, kind: kind, unit: unit)),
              ),
          ActionChip(
            avatar: const Icon(Icons.add_circle, size: 16),
            label: const Text('Custom item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            visualDensity: VisualDensity.compact,
            onPressed: () => _edit(context),
          ),
        ]),
        if (components.isNotEmpty) ...[
          const SizedBox(height: 8),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) {
              final next = [...components];
              final item = next.removeAt(from);
              next.insert(to, item);
              onChanged(next);
            },
            children: [
              for (var i = 0; i < components.length; i++)
                ListTile(
                  key: ValueKey('pc_$i${components[i].label}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                  title: Text(components[i].label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${switch (components[i].kind) {
                      PriceKind.charge => 'Charge',
                      PriceKind.deposit => 'Refundable deposit (not in total)',
                      PriceKind.discount => 'Discount',
                    }} • ${components[i].unitLabel}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '${components[i].kind == PriceKind.discount ? '−' : ''}${rs(components[i].amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: components[i].kind == PriceKind.discount ? Colors.green : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _edit(context, index: i),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => onChanged([...components]..removeAt(i)),
                    ),
                  ]),
                ),
            ],
          ),
        ],
        const Divider(height: 20),
        Text('Customer preview (1 day, 1 person)', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        for (final l in preview.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text(l.label, style: const TextStyle(fontSize: 12.5))),
              Text('${l.amount < 0 ? '−' : ''}${rs(l.amount)}',
                  style: TextStyle(fontSize: 12.5, color: l.amount < 0 ? Colors.green : null)),
            ]),
          ),
        Row(children: [
          const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
          Text(rs(preview.total), style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        for (final d in preview.deposits)
          Text('+ ${rs(d.amount)} ${d.label} (refundable, collected at pickup)',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _PriceLineDialog extends StatefulWidget {
  final PriceComponent? initial;
  final bool allowPerPerson;
  const _PriceLineDialog({this.initial, required this.allowPerPerson});

  @override
  State<_PriceLineDialog> createState() => _PriceLineDialogState();
}

class _PriceLineDialogState extends State<_PriceLineDialog> {
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _amount = TextEditingController(
      text: (widget.initial?.amount ?? 0) == 0 ? '' : widget.initial!.amount.toStringAsFixed(0));
  late PriceKind _kind = widget.initial?.kind ?? PriceKind.charge;
  late PriceUnit _unit = widget.initial?.unit ?? PriceUnit.perBooking;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = [PriceUnit.perBooking, PriceUnit.perDay, if (widget.allowPerPerson) PriceUnit.perPerson];
    if (!units.contains(_unit)) _unit = PriceUnit.perBooking;
    return AlertDialog(
      title: Text(widget.initial?.label.isNotEmpty == true ? 'Edit price line' : 'Add price line'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name (e.g. Helmet, Cleaning fee)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
          ),
          const SizedBox(height: 12),
          SegmentedButton<PriceKind>(
            segments: const [
              ButtonSegment(value: PriceKind.charge, label: Text('Charge')),
              ButtonSegment(value: PriceKind.deposit, label: Text('Deposit')),
              ButtonSegment(value: PriceKind.discount, label: Text('Discount')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<PriceUnit>(
            initialValue: _unit,
            decoration: const InputDecoration(labelText: 'Charged'),
            items: [
              for (final u in units)
                DropdownMenuItem(
                  value: u,
                  child: Text(PriceComponent(label: '', amount: 0, unit: u).unitLabel),
                ),
            ],
            onChanged: (u) => setState(() => _unit = u ?? PriceUnit.perBooking),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final label = _label.text.trim();
            final amount = double.tryParse(_amount.text.trim()) ?? 0;
            if (label.isEmpty || amount <= 0) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Enter a name and an amount above ₹0')));
              return;
            }
            Navigator.pop(context, PriceComponent(label: label, amount: amount, kind: _kind, unit: _unit));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
