import 'package:collection/collection.dart';

/// High-level intents for Ask Altu queries.
enum AskAltuIntent {
  sleep,
  activity,
  screenTime,
  correlations,
  goals,
  general,
}

/// Lightweight, rule-based intent router.
///
/// MVP-friendly: avoids additional dependencies and is deterministic.
class IntentRouter {
  const IntentRouter();

  AskAltuIntent route(String query) {
    final q = query.toLowerCase();

    final checks = <AskAltuIntent, List<String>>{
      AskAltuIntent.sleep: [
        'sleep',
        'bed',
        'insomnia',
        'nap',
        'rest',
      ],
      AskAltuIntent.activity: [
        'workout',
        'steps',
        'run',
        'walk',
        'exercise',
        'fitness',
        'productive',
        'productivity',
      ],
      AskAltuIntent.screenTime: [
        'screen',
        'phone',
        'app',
        'tiktok',
        'instagram',
        'netflix',
        'youtube',
        'scroll',
      ],
      AskAltuIntent.correlations: [
        'correlat',
        'impact',
        'affect',
        'connection',
        'relationship',
      ],
      AskAltuIntent.goals: [
        'goal',
        'score',
        'streak',
        'target',
      ],
    };

    final match = checks.entries.firstWhereOrNull(
      (entry) => entry.value.any((kw) => q.contains(kw)),
    );

    return match?.key ?? AskAltuIntent.general;
  }
}

