import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/kinetic_trust_engine.dart';
import '../theme/app_colors.dart';

/// Renter reputation screen: shows the live Kinetic Trust Score, every
/// component of the formula, and how each booking affected it.
class KineticTrustScreen extends StatefulWidget {
  const KineticTrustScreen({super.key});

  @override
  State<KineticTrustScreen> createState() => _KineticTrustScreenState();
}

class _KineticTrustScreenState extends State<KineticTrustScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().syncKineticTrustScore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = appState.kineticTrust;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (!appState.popNav()) appState.setNavIndex(16);
              },
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SECURITY & REPUTATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                  )),
              const Text('Kinetic Trust Score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
          ]),
          const SizedBox(height: 16),
          _hero(r, isDark),
          const SizedBox(height: 16),
          _stats(r, scheme),
          const SizedBox(height: 24),
          const Text('Score breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('S = 100 × (0.40·R + 0.25·P + 0.20·V + 0.15·E)',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _component(
            'Reliability (R)',
            'Rides completed vs. cancellations & no-shows',
            r.reliability,
            KineticTrustEngine.wReliability,
            AppColors.primary,
            'R = (Σw·completed + 3·0.85) / (Σw·completed + Σw·c(h) + Σw·1.5·no-show + 3)\n'
                'c(h) = e^(−h/24): cancelling h hours before start. 1 day ahead costs 0.37, '
                '3 days ahead 0.05, after start 1.0. Host cancellations never count against you.',
            scheme,
          ),
          _component(
            'Punctuality (P)',
            'On-time pickup and return',
            r.punctuality,
            KineticTrustEngine.wPunctuality,
            AppColors.secondary,
            'P = (Σw·sᵢ + 2·0.85) / (Σw + 2)\n'
            'sᵢ = e^(−late return min/120) · e^(−late pickup min/240), with 15 min pickup grace. '
                '1 h late return → 0.61, 2 h → 0.37.',
            scheme,
          ),
          _component(
            'Verification (V)',
            'Driving License + Aadhaar on file',
            r.verification,
            KineticTrustEngine.wVerification,
            Colors.teal,
            'V = 0.6 × License (verified & valid = 1, pending = 0.5) + 0.4 × Aadhaar on file',
            scheme,
          ),
          _component(
            'Experience (E)',
            'Number of completed rides',
            r.experience,
            KineticTrustEngine.wExperience,
            Colors.deepPurple,
            'E = 1 − e^(−completed/5): 1 ride → 0.18, 5 → 0.63, 15 → 0.95',
            scheme,
          ),
          const SizedBox(height: 8),
          Text(
            'Recency: every booking is weighted w = 2^(−age/180 days), so a cancellation from 6 months ago '
            'counts half as much as one today. New riders start from a neutral prior of 0.85 instead of 0 or 100.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 24),
          const Text('How to improve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._tips(r, appState, scheme),
          const SizedBox(height: 24),
          if (r.badges.isNotEmpty) ...[
            const Text('Badges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final b in r.badges)
                Chip(
                  avatar: const Icon(Icons.verified, size: 16, color: AppColors.secondary),
                  label: Text(b, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
            ]),
            const SizedBox(height: 24),
          ],
          const Text('Booking history impact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (r.events.isEmpty)
            Text('No bookings yet. Your score starts from verification and grows with every completed ride.',
                style: TextStyle(color: scheme.onSurfaceVariant))
          else
            for (final e in r.events.take(20)) _eventTile(e, scheme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 90) return const Color(0xFF2E7D32);
    if (s >= 75) return const Color(0xFF558B2F);
    if (s >= 60) return const Color(0xFFF9A825);
    if (s >= 40) return const Color(0xFFEF6C00);
    return const Color(0xFFC62828);
  }

  Widget _hero(KineticTrustReport r, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
              : [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            height: 130,
            width: 130,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: r.score / 100),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 11,
                backgroundColor: Colors.white24,
                color: _scoreColor(r.score),
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(r.score.toStringAsFixed(1),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('/ 100', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: _scoreColor(r.score), borderRadius: BorderRadius.circular(20)),
          child: Text(r.tier.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hosts see this score when you book. It is calculated from how you book, ride, return and cancel.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ]),
    );
  }

  Widget _stats(KineticTrustReport r, ColorScheme scheme) {
    Widget tile(String value, String label, IconData icon, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: scheme.onSurface)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
            ]),
          ),
        );
    return Column(children: [
      Row(children: [
        tile('${r.completed}', 'Completed', Icons.check_circle, Colors.green),
        const SizedBox(width: 8),
        tile('${r.customerCancellations}', 'Cancelled\n(${r.lastMinuteCancellations} last-minute)', Icons.cancel,
            Colors.red),
        const SizedBox(width: 8),
        tile('${r.noShows}', 'No-shows', Icons.person_off, Colors.deepOrange),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        tile('${(r.cancellationRate * 100).toStringAsFixed(0)}%', 'Cancel rate', Icons.percent, Colors.purple),
        const SizedBox(width: 8),
        tile('${r.avgLateReturnMinutes.round()} min', 'Avg late return', Icons.schedule, Colors.blue),
        const SizedBox(width: 8),
        tile('${r.totalBookings}', 'Total bookings', Icons.receipt_long, Colors.teal),
      ]),
    ]);
  }

  Widget _component(String title, String subtitle, double value, double weight, Color color, String formula,
      ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${(value * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
              Text('+${(value * weight * 100).toStringAsFixed(1)} pts',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ]),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 7,
                color: color,
                backgroundColor: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(formula,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.45, color: scheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tips(KineticTrustReport r, AppState appState, ColorScheme scheme) {
    final tips = <(IconData, String, VoidCallback?)>[];
    if (r.verification < 1) {
      tips.add((
        Icons.badge_outlined,
        'Upload & verify your Driving License and Aadhaar: up to +${((1 - r.verification) * 20).toStringAsFixed(0)} pts',
        () => appState.setNavIndex(14),
      ));
    }
    if (r.lastMinuteCancellations > 0 || r.customerCancellations > 0) {
      tips.add((
        Icons.event_busy,
        'If you must cancel, do it 2+ days early: the penalty falls from 1.0 to under 0.15',
        null,
      ));
    }
    if (r.noShows > 0) {
      tips.add((Icons.person_off, 'Avoid no-shows: they cost 1.5× a last-minute cancellation', null));
    }
    if (r.punctuality < 0.9) {
      tips.add((Icons.schedule, 'Return the bike on time: every hour late reduces that ride\'s score by ~40%', null));
    }
    if (r.experience < 0.95) {
      tips.add((Icons.two_wheeler, 'Complete more rides: experience grows quickly over your first 5–15 rides', null));
    }
    if (tips.isEmpty) {
      tips.add((Icons.emoji_events, 'Excellent! Keep riding reliably to stay at the top tier.', null));
    }
    return [
      for (final t in tips)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: Icon(t.$1, color: AppColors.primary),
          title: Text(t.$2, style: TextStyle(fontSize: 13, color: scheme.onSurface)),
          trailing: t.$3 == null ? null : const Icon(Icons.chevron_right),
          onTap: t.$3,
        ),
    ];
  }

  Widget _eventTile(TrustEvent e, ColorScheme scheme) {
    final (IconData icon, Color color) = switch (e.kind) {
      'completed' => (Icons.check_circle, Colors.green),
      'cancelled' => (Icons.cancel, Colors.red),
      'no_show' => (Icons.person_off, Colors.deepOrange),
      'host_cancelled' => (Icons.info_outline, Colors.blueGrey),
      _ => (Icons.schedule, Colors.blue),
    };
    final date = DateFormat('d MMM yyyy').format(e.booking.startDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.booking.vehicleTitle.isEmpty ? 'Booking' : e.booking.vehicleTitle} · $date',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: scheme.onSurface)),
            Text(e.label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            Text(e.detail, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }
}
