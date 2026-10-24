import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  Timer? _autoRefreshTimer;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    // Auto-refresh every 10 seconds to keep live data synced
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadMetrics(isSilent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMetrics({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() => _isLoading = true);
    }
    final appState = Provider.of<AppState>(context, listen: false);
    final metrics = await appState.supabaseService.getDashboardMetrics();
    if (!mounted) return;
    setState(() {
      _metrics = metrics;
      _isLoading = false;
      _lastUpdated = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final totalUsers = _metrics['totalUsers'] ?? 0;
    final activeVehicles = _metrics['activeVehicles'] ?? 0;
    final totalVehicles = _metrics['totalVehicles'] ?? activeVehicles;
    final completedBookings = _metrics['completedBookings'] ?? 0;
    final totalBookings = _metrics['totalBookings'] ?? completedBookings;
    final totalRevenue = (_metrics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final platformCommission = totalRevenue * 0.15;
    final pendingHosts = _metrics['pendingVerifications'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadMetrics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission Control Overview',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live sync every 10s • Updated ${DateFormat('HH:mm:ss').format(_lastUpdated)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _loadMetrics(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMetricsGrid(
              totalUsers: totalUsers,
              activeVehicles: activeVehicles,
              totalVehicles: totalVehicles,
              completedBookings: completedBookings,
              totalBookings: totalBookings,
              totalRevenue: totalRevenue,
              platformCommission: platformCommission,
              pendingHosts: pendingHosts,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 32),
            Text(
              'Gross Booking Volume Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChartContainer(isDark, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid({
    required int totalUsers,
    required int activeVehicles,
    required int totalVehicles,
    required int completedBookings,
    required int totalBookings,
    required double totalRevenue,
    required double platformCommission,
    required int pendingHosts,
    required NumberFormat currencyFormat,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 550 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 900 ? 1.8 : 2.1,
          children: [
            _buildMetricCard(
              'Gross Booking Value',
              currencyFormat.format(totalRevenue),
              'Total GMV confirmed',
              Icons.currency_rupee,
              Colors.blue.shade700,
            ),
            _buildMetricCard(
              'Est. Platform Cut (15%)',
              currencyFormat.format(platformCommission),
              'Net commission earned',
              Icons.account_balance_wallet,
              Colors.teal.shade700,
            ),
            _buildMetricCard(
              'Active / Available Fleet',
              '$activeVehicles / $totalVehicles',
              'Ready for immediate booking',
              Icons.directions_car,
              Colors.orange.shade700,
            ),
            _buildMetricCard(
              'Confirmed Bookings',
              '$completedBookings / $totalBookings',
              'Active or completed trips',
              Icons.check_circle_outline,
              Colors.green.shade700,
            ),
            _buildMetricCard(
              'Registered Accounts',
              '$totalUsers',
              'Verified riders & hosts',
              Icons.group,
              Colors.purple.shade700,
            ),
            _buildMetricCard(
              'Host Verifications',
              '$pendingHosts Pending',
              'Awaiting identity approval',
              Icons.verified_user_outlined,
              Colors.amber.shade800,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(bool isDark, NumberFormat currencyFormat) {
    final rawBookings = (_metrics['rawBookings'] as List?) ?? [];
    
    // Group booking total prices into chart points
    List<FlSpot> spots = [];
    if (rawBookings.isNotEmpty) {
      double cumulative = 0.0;
      for (int i = 0; i < rawBookings.length; i++) {
        final price = (rawBookings[i]['total_price'] as num?)?.toDouble() ?? 0.0;
        cumulative += price;
        spots.add(FlSpot(i.toDouble(), cumulative));
      }
    }

    if (spots.isEmpty) {
      spots = const [
        FlSpot(0, 0),
        FlSpot(1, 1000),
        FlSpot(2, 2500),
        FlSpot(3, 4800),
        FlSpot(4, 7500),
      ];
    }

    final maxY = (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.15).clamp(100.0, 100000.0);

    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cumulative Volume Growth',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                currencyFormat.format(spots.last.y),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          val >= 1000 ? '₹${(val / 1000).toStringAsFixed(0)}k' : '₹${val.toInt()}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          'B#${val.toInt() + 1}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
