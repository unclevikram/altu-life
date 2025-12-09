import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/data/data_processing.dart';
import 'package:altu_life/features/insights/presentation/widgets/best_day_card.dart';
import 'package:altu_life/features/insights/presentation/widgets/insight_card.dart';
import 'package:altu_life/features/insights/presentation/widgets/personal_best_card.dart';
import 'package:altu_life/features/insights/presentation/widgets/productivity_sleep_chart.dart';
import 'package:altu_life/providers/health_providers.dart';
import 'package:altu_life/shared/widgets/widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Insights screen displaying deep analysis and correlations.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepLagStats = ref.watch(sleepAfterWorkoutProvider);
    final prodVsSleepData = ref.watch(productivityVsSleepProvider);
    final lowStepStats = ref.watch(lowStepStatsProvider);
    final bests = ref.watch(personalBestsProvider);
    final sleepConsistency = ref.watch(sleepConsistencyStatsProvider);
    final appCorrelations = ref.watch(appHealthCorrelationsProvider);
    final recoveryStats = ref.watch(recoverySleepStatsProvider);
    final workoutStreaks = ref.watch(workoutStreakStatsProvider);

    if (bests == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand500),
      );
    }

    // Get safe area padding to avoid status bar overlap
    final topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      color: AppColors.brand500,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 100),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          // Header
          const Text(
            'Insights',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'Deep analysis of your habits & correlations',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 24),

          // WHAT'S WORKING SECTION
          const SectionHeader(
            icon: LucideIcons.flame,
            title: "What's Working",
            color: AppColors.teal600,
          ),

          // Sleep Lag Insight - only show if workout gives more sleep
          if (sleepLagStats.afterWorkout > sleepLagStats.afterRest)
            InsightCard(
              iconBackgroundColor: AppColors.violet100,
              iconColor: AppColors.violet700,
              icon: LucideIcons.moon,
              title: 'Workouts help you sleep better',
              description:
                  'On nights after you exercise, you sleep ${sleepLagStats.afterWorkout - sleepLagStats.afterRest} extra minutes. That\'s ${_formatHours(sleepLagStats.afterWorkout)} vs ${_formatHours(sleepLagStats.afterRest)}!',
              chart: Row(
                children: [
                  Expanded(
                    child: _buildSleepStatBox(
                      'Post-Workout',
                      _formatHours(sleepLagStats.afterWorkout),
                      AppColors.violet50,
                      AppColors.violet600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSleepStatBox(
                      'Normal Night',
                      _formatHours(sleepLagStats.afterRest),
                      AppColors.slate50,
                      AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Sleep Consistency - only show if consistency score is good
          if (sleepConsistency.consistencyScore >= 70)
            InsightCard(
              iconBackgroundColor: AppColors.indigo100,
              iconColor: AppColors.indigo700,
              icon: LucideIcons.clock,
              title: 'Your sleep schedule is consistent!',
              description:
                  'Your sleep varies by only ${sleepConsistency.stdDev} minutes per night. This consistency is great for your circadian rhythm and overall health!',
              chart: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.indigo50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.indigo100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.checkCircle,
                      color: AppColors.indigo600,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consistency Score',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.indigo600,
                          ),
                        ),
                        Text(
                          '${sleepConsistency.consistencyScore}/100',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.indigo700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Recovery Sleep - inspired by Whoop's recovery insights
          if (recoveryStats.afterHighExertion > recoveryStats.afterLowExertion)
            InsightCard(
              iconBackgroundColor: AppColors.purple500.withValues(alpha: 0.1),
              iconColor: AppColors.purple500,
              icon: LucideIcons.batteryCharging,
              title: 'Your body knows how to recover',
              description:
                  'After high-exertion days, you naturally sleep ${recoveryStats.afterHighExertion - recoveryStats.afterLowExertion} minutes more (${_formatHours(recoveryStats.afterHighExertion)} vs ${_formatHours(recoveryStats.afterLowExertion)}). Your recovery system is working!',
              chart: Row(
                children: [
                  Expanded(
                    child: _buildRecoveryBox(
                      label: 'High Exertion',
                      value: _formatHours(recoveryStats.afterHighExertion),
                      icon: LucideIcons.zap,
                      isHighlighted: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRecoveryBox(
                      label: 'Low Exertion',
                      value: _formatHours(recoveryStats.afterLowExertion),
                      icon: LucideIcons.moon,
                      isHighlighted: false,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Workout Streaks - gamification element
          if (workoutStreaks.maxStreak >= 2)
            InsightCard(
              iconBackgroundColor: AppColors.amber100,
              iconColor: AppColors.amber600,
              icon: LucideIcons.flame,
              title: 'Streak master! 🔥',
              description:
                  'Your longest workout streak is ${workoutStreaks.maxStreak} days! You\'ve had ${workoutStreaks.totalStreaks} workout streaks averaging ${workoutStreaks.avgStreak} days each.',
              chart: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.amber50, AppColors.amber100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.amber200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStreakStat('Max Streak', '${workoutStreaks.maxStreak}', LucideIcons.trophy),
                    Container(width: 1, height: 40, color: AppColors.amber200),
                    _buildStreakStat('Total Streaks', '${workoutStreaks.totalStreaks}', LucideIcons.target),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),

          // OPPORTUNITIES SECTION
          const SectionHeader(
            icon: LucideIcons.alertTriangle,
            title: 'Opportunities',
            color: AppColors.rose500,
          ),

          // App-Health Correlations Insight - data-driven from correlation analysis
          ..._buildTopCorrelationInsights(appCorrelations),

          // Productivity vs Sleep - reframed positively
          InsightCard(
            title: 'Lighter work days = better rest',
            description:
                _buildProductivityInsightText(prodVsSleepData),
            chart: ProductivitySleepChart(
              data: prodVsSleepData.length > 14
                  ? prodVsSleepData.sublist(prodVsSleepData.length - 14)
                  : prodVsSleepData,
            ),
            footer: const Text(
              'Line: Sleep Hrs • Bars: Work Mins',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.slate400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Active days insight - reframed positively
          if (lowStepStats.high.activeEnergy > lowStepStats.low.activeEnergy)
            InsightCard(
              title: 'Active days boost your energy burn',
              description:
                  'On days with 5k+ steps, you burn ${lowStepStats.high.activeEnergy - lowStepStats.low.activeEnergy} more calories! You also spend ${lowStepStats.low.screen - lowStepStats.high.screen} fewer minutes on screens.',
            chart: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orange100),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.footprints,
                    color: AppColors.orange400,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    LucideIcons.arrowRight,
                    color: AppColors.orange300,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Low Step Days',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange800,
                        ),
                      ),
                      Text(
                        '-${lowStepStats.high.activeEnergy - lowStepStats.low.activeEnergy} kcal burned',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.orange600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // PERSONAL BESTS SECTION
          const SectionHeader(
            icon: LucideIcons.trophy,
            title: 'Personal Bests',
            color: AppColors.amber500,
          ),

          // Bests grid - 2x2 layout
          Row(
            children: [
              Expanded(
                child: PersonalBestCard(
                  label: 'Most Steps',
                  value: _formatNumber(bests.steps.steps),
                  date: bests.steps.date,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PersonalBestCard(
                  label: 'Longest Workout',
                  value: '${bests.workout.workoutMinutes} min',
                  date: bests.workout.date,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PersonalBestCard(
                  label: 'Best Sleep',
                  value: '${(bests.sleep.sleepMinutes / 60).toStringAsFixed(1)} hrs',
                  date: bests.sleep.date,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PersonalBestCard(
                  label: 'Max Energy',
                  value: '${bests.energy.activeEnergy} kcal',
                  date: bests.energy.date,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Best Day Deep Dive
          BestDayCard(bestDay: bests.bestDay),
        ],
      ),
    );
  }

  Widget _buildSleepStatBox(
    String label,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(int mins) {
    final hours = mins ~/ 60;
    final minutes = mins % 60;
    return '${hours}h ${minutes}m';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }

  String _buildProductivityInsightText(List<ProductivitySleepData> data) {
    // Calculate actual averages for high vs low productivity days
    final highProdDays = data.where((d) => d.productivity > 100).toList();
    final lowProdDays = data.where((d) => d.productivity < 50).toList();

    if (highProdDays.isEmpty || lowProdDays.isEmpty) {
      return 'Balance work app time with rest for better sleep quality.';
    }

    final highProdSleep = highProdDays
        .map((d) => d.sleepHours)
        .reduce((a, b) => a + b) / highProdDays.length;
    final lowProdSleep = lowProdDays
        .map((d) => d.sleepHours)
        .reduce((a, b) => a + b) / lowProdDays.length;

    final diff = (lowProdSleep - highProdSleep).abs();

    if (lowProdSleep > highProdSleep) {
      return 'Days with lighter Slack/Gmail use (${lowProdSleep.toStringAsFixed(1)}h sleep) beat heavy work days (${highProdSleep.toStringAsFixed(1)}h) by ${diff.toStringAsFixed(1)} hours. Try setting boundaries!';
    } else {
      return 'Your work-life balance is working! Keep maintaining healthy boundaries with productivity apps.';
    }
  }

  List<Widget> _buildTopCorrelationInsights(List<AppHealthCorrelation> correlations) {
    final insights = <Widget>[];

    // Find strongest sleep correlations (negative = opportunity, positive = what's working)
    final sleepCorrelations = correlations.where((c) => c.metric == 'sleep').toList();

    if (sleepCorrelations.isNotEmpty) {
      final topNegative = sleepCorrelations.where((c) => c.correlation < -0.4).firstOrNull;

      // Add negative correlation as opportunity
      if (topNegative != null) {
        insights.add(
          InsightCard(
            iconBackgroundColor: AppColors.rose100,
            iconColor: AppColors.rose600,
            icon: LucideIcons.alertCircle,
            title: '${topNegative.app} impacts your sleep',
            description:
                'Strong pattern detected: ${topNegative.app} usage correlates with less sleep (${topNegative.correlation.toStringAsFixed(2)} correlation). Consider reducing usage before bed.',
            chart: _buildCorrelationBadge(topNegative.correlation, isNegative: true),
          ),
        );
        insights.add(const SizedBox(height: 16));
      }
    }

    return insights;
  }

  Widget _buildCorrelationBadge(double correlation, {required bool isNegative}) {
    final absCorr = correlation.abs();
    final strength = absCorr >= 0.5 ? 'Strong' : 'Moderate';
    final color = isNegative ? AppColors.rose500 : AppColors.emerald500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNegative ? LucideIcons.trendingDown : LucideIcons.trendingUp,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$strength Correlation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                correlation.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryBox({
    required String label,
    required String value,
    required IconData icon,
    required bool isHighlighted,
  }) {
    final bgColor = isHighlighted ? AppColors.purple500.withValues(alpha: 0.15) : AppColors.slate50;
    final iconColor = isHighlighted ? AppColors.purple500 : AppColors.slate400;
    final textColor = isHighlighted ? AppColors.purple500 : AppColors.slate600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppColors.purple500.withValues(alpha: 0.3) : AppColors.slate200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.amber600, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.amber700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.amber600,
          ),
        ),
      ],
    );
  }
}

