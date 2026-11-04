/// One provider-defined line in a listing's price breakdown
/// (e.g. "Helmet rental ₹50 / day", "Cleaning fee ₹100", "Security deposit ₹2000").
enum PriceUnit { perBooking, perDay, perPerson }

enum PriceKind {
  charge, // added to the total
  deposit, // shown, collected at pickup, refunded later — not added to the total
  discount, // subtracted from the total
}

class PriceComponent {
  final String label;
  final double amount;
  final PriceUnit unit;
  final PriceKind kind;

  const PriceComponent({
    required this.label,
    required this.amount,
    this.unit = PriceUnit.perBooking,
    this.kind = PriceKind.charge,
  });

  PriceComponent copyWith({String? label, double? amount, PriceUnit? unit, PriceKind? kind}) => PriceComponent(
        label: label ?? this.label,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
        kind: kind ?? this.kind,
      );

  Map<String, dynamic> toMap() => {'label': label, 'amount': amount, 'unit': unit.name, 'kind': kind.name};

  factory PriceComponent.fromMap(Map m) => PriceComponent(
        label: '${m['label'] ?? ''}',
        amount: double.tryParse('${m['amount']}') ?? 0,
        unit: PriceUnit.values.firstWhere((u) => u.name == m['unit'], orElse: () => PriceUnit.perBooking),
        kind: PriceKind.values.firstWhere((k) => k.name == m['kind'], orElse: () => PriceKind.charge),
      );

  static List<PriceComponent> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final m in raw)
        if (m is Map && '${m['label'] ?? ''}'.trim().isNotEmpty) PriceComponent.fromMap(m),
    ];
  }

  static List<Map<String, dynamic>> listTo(List<PriceComponent> list) => [for (final c in list) c.toMap()];

  String get unitLabel => switch (unit) {
        PriceUnit.perBooking => 'per booking',
        PriceUnit.perDay => 'per day',
        PriceUnit.perPerson => 'per person',
      };

  /// Amount for this booking, given days and people.
  double lineTotal({int days = 1, int people = 1}) => switch (unit) {
        PriceUnit.perBooking => amount,
        PriceUnit.perDay => amount * (days < 1 ? 1 : days),
        PriceUnit.perPerson => amount * (people < 1 ? 1 : people),
      };
}

/// A computed breakdown shown at checkout.
class PriceBreakdownLine {
  final String label;
  final double amount; // signed: negative for discounts
  final bool isDeposit;
  const PriceBreakdownLine(this.label, this.amount, {this.isDeposit = false});
}

class PriceBreakdown {
  final List<PriceBreakdownLine> lines; // charges and discounts (counted in total)
  final List<PriceBreakdownLine> deposits; // shown separately, not counted
  final double total;
  const PriceBreakdown(this.lines, this.deposits, this.total);

  /// [baseLabel]/[base] is the listing's main price; [components] are the provider's extra lines.
  static PriceBreakdown build({
    required String baseLabel,
    required double base,
    required List<PriceComponent> components,
    int days = 1,
    int people = 1,
  }) {
    final lines = <PriceBreakdownLine>[PriceBreakdownLine(baseLabel, base)];
    final deposits = <PriceBreakdownLine>[];
    var total = base;
    for (final c in components) {
      final amt = c.lineTotal(days: days, people: people);
      final suffix = c.unit == PriceUnit.perBooking
          ? ''
          : c.unit == PriceUnit.perDay
              ? ' (₹${_fmt(c.amount)} × $days day${days == 1 ? '' : 's'})'
              : ' (₹${_fmt(c.amount)} × $people)';
      switch (c.kind) {
        case PriceKind.charge:
          lines.add(PriceBreakdownLine('${c.label}$suffix', amt));
          total += amt;
        case PriceKind.discount:
          lines.add(PriceBreakdownLine('${c.label}$suffix', -amt));
          total -= amt;
        case PriceKind.deposit:
          deposits.add(PriceBreakdownLine('${c.label}$suffix', amt, isDeposit: true));
      }
    }
    return PriceBreakdown(lines, deposits, total < 0 ? 0 : total);
  }

  static String _fmt(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}
