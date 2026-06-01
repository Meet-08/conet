import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_count.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_trend.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_analytics_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventAnalyticsPage extends StatefulWidget {
  final String eventId;
  const EventAnalyticsPage({super.key, required this.eventId});

  @override
  State<EventAnalyticsPage> createState() => _EventAnalyticsPageState();
}

class _EventAnalyticsPageState extends State<EventAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventAnalyticsBloc>().add(
        EventAnalyticsLoadRequested(eventId: widget.eventId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Scaffold(
      backgroundColor: semantic.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: semantic.backgroundPrimary,
        foregroundColor: semantic.iconPrimary,
        title: Text(
          'Analytics',
          style: AppTextStyles.headingH3.copyWith(color: semantic.textPrimary),
        ),
      ),
      body: BlocBuilder<EventAnalyticsBloc, EventAnalyticsState>(
        builder: (_, state) {
          if (state is EventAnalyticsLoading ||
              state is EventAnalyticsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventAnalyticsFailure) {
            return Center(
              child: Text(
                state.message,
                style: AppTextStyles.bodyDefault.copyWith(
                  color: semantic.textSecondary,
                ),
              ),
            );
          }
          final loaded = state as EventAnalyticsLoaded;
          final vm = _AnalyticsVM.from(
            loaded.event,
            loaded.attendees,
            loaded.trend,
            loaded.collegeCounts,
            loaded.courseCounts,
          );
          return RefreshIndicator(
            onRefresh: () async {
              context.read<EventAnalyticsBloc>().add(
                EventAnalyticsLoadRequested(eventId: widget.eventId),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.s16),
              children: [
                _HeaderCard(vm: vm),
                const SizedBox(height: AppSpace.s16),
                _StatsRow(vm: vm),
                const SizedBox(height: AppSpace.s16),
                _TrendCard(vm: vm),
                const SizedBox(height: AppSpace.s16),
                _RankingCard(title: 'Top Colleges', items: vm.topColleges),
                const SizedBox(height: AppSpace.s16),
                _RankingCard(title: 'Top branch', items: vm.topBranches),
                const SizedBox(height: AppSpace.s16),
                _QuickActions(eventId: widget.eventId, eventTitle: vm.title),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final _AnalyticsVM vm;
  const _HeaderCard({required this.vm});
  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: semantic.surfaceBase,
        border: Border.all(color: semantic.borderDefault),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vm.title,
            style: AppTextStyles.label.copyWith(
              color: semantic.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          _Meta(icon: FontAwesomeIcons.calendar, text: vm.date),
          const SizedBox(height: AppSpace.s6),
          _Meta(icon: FontAwesomeIcons.locationDot, text: vm.location),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Row(
      children: [
        FaIcon(icon, size: 12, color: semantic.iconSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: semantic.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _AnalyticsVM vm;
  const _StatsRow({required this.vm});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'REGISTRATIONS',
                value: '${vm.registrations}',
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: _StatTile(label: 'CHECK-INS', value: '${vm.checkIns}'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s12),
        _StatTile(label: 'REVENUE', value: vm.revenue),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: semantic.surfaceBase,
        border: Border.all(color: semantic.borderDefault),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.micro.copyWith(
              color: semantic.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Text(
            value,
            style: AppTextStyles.headingH1.copyWith(
              color: semantic.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final _AnalyticsVM vm;

  const _TrendCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registration Trend',
          style: AppTextStyles.label.copyWith(
            color: semantic.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s12,
          ),
          decoration: BoxDecoration(
            color: semantic.surfaceBase,
            border: Border.all(color: semantic.borderDefault),
            borderRadius: AppRadius.lgAll,
          ),
          height: 180,
          child: vm.trendPoints.isEmpty
              ? Center(
                  child: Text(
                    'No registration trend data',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: semantic.textSecondary,
                    ),
                  ),
                )
              : LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (vm.trendPoints.length - 1).toDouble(),
                    minY: 0,
                    maxY: vm.maxTrendY.toDouble(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: vm.yInterval.toDouble(),
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: semantic.borderSubtle, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: vm.yInterval.toDouble(),
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: AppTextStyles.micro.copyWith(
                              color: semantic.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: vm.xLabelInterval.toDouble(),
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= vm.trendLabels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                width: 60,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    vm.trendLabels[index],
                                    style: AppTextStyles.micro.copyWith(
                                      color: semantic.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: vm.trendPoints,
                        color: semantic.iconPrimary,
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                            radius: 2,
                            color: semantic.iconPrimary,
                            strokeWidth: 0,
                          ),
                        ),
                        isCurved: false,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  final String title;
  final List<MapEntry<String, int>> items;
  const _RankingCard({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final visibleItems = items.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.label.copyWith(
            color: semantic.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Container(
          padding: const EdgeInsets.all(AppSpace.s12),
          decoration: BoxDecoration(
            color: semantic.surfaceBase,
            border: Border.all(color: semantic.borderDefault),
            borderRadius: AppRadius.lgAll,
          ),
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: semantic.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: visibleItems.asMap().entries.map((row) {
                    final i = row.key;
                    final item = row.value;
                    final isLast = i == visibleItems.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : AppSpace.s10,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: semantic.surfaceRaised,
                                borderRadius: AppRadius.fullAll,
                                border: Border.all(
                                  color: semantic.borderDefault,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: AppTextStyles.caption.copyWith(
                                  color: semantic.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.s16),
                            Expanded(
                              child: Text(
                                item.key,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyDefault.copyWith(
                                  color: semantic.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.s12),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${item.value}',
                                textAlign: TextAlign.end,
                                style: AppTextStyles.bodyDefault.copyWith(
                                  color: semantic.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  const _QuickActions({required this.eventId, required this.eventTitle});
  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.label.copyWith(
            color: semantic.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  '/event-attendance-scan',
                  extra: {'eventId': eventId, 'eventTitle': eventTitle},
                ),
                icon: const FaIcon(FontAwesomeIcons.qrcode, size: 14),
                label: const Text('Scan Tickets'),
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final encoded = Uri.encodeComponent(eventTitle);
                  context.push('/event-attendees/$eventId?title=$encoded');
                },
                icon: const FaIcon(FontAwesomeIcons.users, size: 14),
                label: const Text('Participants'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalyticsVM {
  final String title;
  final String date;
  final String location;
  final int registrations;
  final int checkIns;
  final String revenue;
  final List<MapEntry<String, int>> topColleges;
  final List<MapEntry<String, int>> topBranches;
  final List<FlSpot> trendPoints;
  final List<String> trendLabels;
  final int maxTrendY;
  final int yInterval;
  final int xLabelInterval;
  const _AnalyticsVM({
    required this.title,
    required this.date,
    required this.location,
    required this.registrations,
    required this.checkIns,
    required this.revenue,
    required this.topColleges,
    required this.topBranches,
    required this.trendPoints,
    required this.trendLabels,
    required this.maxTrendY,
    required this.yInterval,
    required this.xLabelInterval,
  });

  factory _AnalyticsVM.from(
    Event event,
    EventAttendees attendees,
    EventRegistrationTrend trend,
    List<EventRegistrationCount> collegeCounts,
    List<EventRegistrationCount> courseCounts,
  ) {
    final isPaid = event.isPaid;
    final paidRegistrations = attendees.attendees
        .where((a) => a.registrationStatus.toLowerCase() != 'cancelled')
        .length;
    final totalRevenue = isPaid ? (event.price ?? 0) * paidRegistrations : 0;
    final sortedTrendPoints = [...trend.points]
      ..sort((a, b) => a.date.compareTo(b.date));
    final spots = sortedTrendPoints
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(entry.key.toDouble(), entry.value.count.toDouble()),
        )
        .toList(growable: false);
    final labels = sortedTrendPoints
        .map((point) => DateFormat('MMM d').format(point.date))
        .toList(growable: false);
    final maxCount = sortedTrendPoints
        .map((point) => point.count)
        .fold<int>(0, (prev, next) => next > prev ? next : prev);
    final axisMax = maxCount <= 0 ? 5 : ((maxCount / 5).ceil() * 5);
    final axisInterval = axisMax <= 5 ? 1 : (axisMax / 5).ceil();
    // Calculate X-axis label interval: show fewer labels when there are many points
    final pointCount = sortedTrendPoints.length;
    final xInterval = pointCount > 15
        ? (pointCount / 5).ceil()
        : (pointCount > 10 ? 2 : 1);

    return _AnalyticsVM(
      title: event.title,
      date: DateFormat('MMM d, y').format(event.startDate),
      location: event.venue ?? event.location ?? 'TBA',
      registrations: attendees.summary.registered,
      checkIns: attendees.summary.attended,
      revenue: '₹${totalRevenue.toStringAsFixed(0)}',
      topColleges: collegeCounts
          .map((item) => MapEntry(item.label, item.count))
          .toList(growable: false),
      topBranches: courseCounts
          .map((item) => MapEntry(item.label, item.count))
          .toList(growable: false),
      trendPoints: spots,
      trendLabels: labels,
      maxTrendY: axisMax,
      yInterval: axisInterval,
      xLabelInterval: xInterval,
    );
  }
}
