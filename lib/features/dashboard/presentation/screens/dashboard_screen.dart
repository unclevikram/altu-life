import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/area_chart_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/bar_chart_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/goal_calendar_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/heatmap_grid_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/line_chart_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/pie_chart_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/radar_chart_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/charts/scatter_chart_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/correlation_flow_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/digital_diet_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/energy_calendar_widget.dart';
import 'package:altu_life/features/dashboard/presentation/widgets/weekday_weekend_widget.dart';
import 'package:altu_life/providers/health_providers.dart';
import 'package:altu_life/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dashboard screen displaying health overview and charts.
///
/// This screen mirrors the React Dashboard component with all
/// the same sections and visualizations.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dateRangeProvider);
    final avgSteps = ref.watch(avgStepsProvider);
    final avgSleep = ref.watch(avgSleepProvider);
    final avgScreen = ref.watch(avgScreenTimeProvider);
    final data = ref.watch(aggregatedDataProvider);
    final sleepStats = ref.watch(sleepQualityStatsProvider);
    final energyData = ref.watch(energyCalendarProvider);
    final categoryData = ref.watch(categoryBreakdownProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final sleepTrend = ref.watch(sleepTrendProvider);
    final weekSplit = ref.watch(weekdayVsWeekendProvider);
    final radarData = ref.watch(weeklyRhythmProvider);
    final appUsageDay = ref.watch(appUsageByDayProvider);
    final goalsData = ref.watch(goalsDataProvider);

    // Get safe area padding to avoid status bar overlap
    final topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      color: AppColors.brand500,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        // In production, this would refresh data from HealthKit
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 100),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          // Header
          _buildHeader(range),
          const SizedBox(height: 16),

          // Date Toggle
          _buildDateToggle(context, ref, range),
          const SizedBox(height: 24),

          // Top Stats Row
          _buildStatsRow(avgSteps, avgSleep, avgScreen),
          const SizedBox(height: 24),

          // Steps Overview Chart
          HealthCard(
            icon: LucideIcons.trendingUp,
            iconColor: AppColors.brand600,
            title: 'Steps Overview',
            child: SizedBox(
              height: 180,
              child: StepsAreaChart(data: data, range: range),
            ),
          ),
          const SizedBox(height: 16),

          // Energy Calendar
          EnergyCalendarWidget(data: energyData, range: range),
          const SizedBox(height: 16),

          // Sleep Quality - comparing activity levels by sleep duration
          HealthCard(
            icon: LucideIcons.activity,
            iconColor: AppColors.violet500,
            title: 'Sleep Duration vs Activity',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compare your average steps and screen time based on how much you slept. Taller bars = higher relative values.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: SleepQualityBarChart(data: sleepStats),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Digital Diet
          DigitalDietWidget(categoryData: categoryData, avgScreen: avgScreen),
          const SizedBox(height: 32),

          // TRENDS SECTION
          const SectionHeader(
            icon: LucideIcons.trendingUp,
            title: 'Trends',
          ),

          // Weekly Health Summary
          HealthCard(
            title: 'Weekly Health Summary',
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: WeeklyLineChart(data: weeklyStats),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Steps', AppColors.brand500),
                    const SizedBox(width: 16),
                    _buildLegendItem('Workouts', AppColors.amber500),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sleep Stability - shows how consistent your sleep is
          HealthCard(
            icon: LucideIcons.moon,
            iconColor: AppColors.violet500,
            title: 'Sleep Stability',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: 'Gray area',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' shows daily sleep hours. '),
                      TextSpan(
                        text: 'Blue line',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue500,
                        ),
                      ),
                      TextSpan(text: ' is the 7-day average. Flatter = more consistent sleep!'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: SleepTrendAreaChart(data: sleepTrend),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // COMPARISONS SECTION
          const SectionHeader(
            icon: LucideIcons.barChart2,
            title: 'Comparisons',
          ),

          // Weekday vs Weekend
          WeekdayVsWeekendWidget(data: weekSplit),
          const SizedBox(height: 32),

          // RHYTHMS SECTION
          const SectionHeader(
            icon: LucideIcons.repeat,
            title: 'Rhythms',
          ),

          // Weekly Rhythm Radar
          HealthCard(
            title: 'Weekly Rhythm',
            child: SizedBox(
              height: 240,
              child: WeeklyRhythmRadar(data: radarData),
            ),
          ),
          const SizedBox(height: 16),

          // App Intensity by Day
          HealthCard(
            icon: LucideIcons.layoutGrid,
            iconColor: AppColors.blue500,
            title: 'App Intensity by Day',
            child: AppUsageHeatmapGrid(data: appUsageDay),
          ),
          const SizedBox(height: 32),

          // GOALS SECTION
          const SectionHeader(
            icon: LucideIcons.target,
            title: 'Goals',
          ),

          // Wellness Score - cumulative health points
          HealthCard(
            icon: LucideIcons.award,
            iconColor: AppColors.amber500,
            title: 'Wellness Score',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // How points are earned
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.amber50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'DAILY POINTS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber600,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 6),
                      _PointsRow(label: 'Workout completed', points: '+10'),
                      SizedBox(height: 4),
                      _PointsRow(label: '8,000+ steps', points: '+5'),
                      SizedBox(height: 4),
                      _PointsRow(label: '7+ hours sleep', points: '+5'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: WellnessScoreChart(data: goalsData),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Max ${goalsData.length * 20} pts possible',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${goalsData.isNotEmpty ? goalsData.last.totalScore : 0} pts',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DateRange range) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Health',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Daily Overview • ${range == DateRange.all ? 'All Time' : 'Last ${range.label}'}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }

  Widget _buildDateToggle(BuildContext context, WidgetRef ref, DateRange range) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: DateRange.values.map((r) {
          final isSelected = range == r;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(dateRangeProvider.notifier).state = r;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  r.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.slate900 : AppColors.slate400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(int avgSteps, int avgSleep, int avgScreen) {
    final sleepHours = avgSleep ~/ 60;
    final sleepMins = avgSleep % 60;
    final screenHours = avgScreen ~/ 60;
    final screenMins = avgScreen % 60;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: LucideIcons.footprints,
            iconColor: AppColors.brand600,
            value: _formatNumber(avgSteps),
            label: 'Avg Steps',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            icon: LucideIcons.moon,
            iconColor: AppColors.violet500,
            value: '${sleepHours}h ${sleepMins}m',
            label: 'Avg Sleep',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            icon: LucideIcons.smartphone,
            iconColor: AppColors.rose500,
            value: '${screenHours}h ${screenMins}m',
            label: 'Daily Screen',
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
}

/// Helper widget to show points breakdown.
class _PointsRow extends StatelessWidget {
  const _PointsRow({
    required this.label,
    required this.points,
  });

  final String label;
  final String points;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.slate600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.amber100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            points,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.amber600,
            ),
          ),
        ),
      ],
    );
  }
}

