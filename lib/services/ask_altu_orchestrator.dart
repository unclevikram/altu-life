import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/features/ask_altu/presentation/providers/chat_provider.dart';
import 'package:altu_life/services/ai_service_manager.dart';
import 'package:altu_life/services/context_shard_builder.dart';
import 'package:altu_life/services/intent_router.dart';

/// Prompt envelope passed to providers.
class AskAltuPrompt {
  AskAltuPrompt({
    required this.systemInstruction,
    required this.conversationHistory,
    required this.temperature,
    required this.maxTokens,
    required this.intent,
  });

  final String systemInstruction;
  final List<Map<String, dynamic>> conversationHistory;
  final double temperature;
  final int maxTokens;
  final AskAltuIntent intent;
}

/// Lightweight guard to ensure we always return something actionable.
class ResponseGuard {
  const ResponseGuard();

  String apply(
    String response,
    AskAltuIntent intent, {
    String? exactFact,
  }) {
    if (response.trim().isEmpty) {
      return 'I had trouble formulating this. Quick takeaway: keep sleep consistent, move daily, and trim late-night screens. Ask again for a deeper dive.';
    }

    // Nudge to include an action if missing.
    final lower = response.toLowerCase();
    final hasAction = lower.contains('try') ||
        lower.contains('consider') ||
        lower.contains('aim') ||
        lower.contains('plan');

    if (!hasAction) {
      response = '$response\n\nAction: choose one small change today that aligns with your goal.';
    }

    if (exactFact != null && exactFact.isNotEmpty) {
      return '$response\n\nExact data: $exactFact';
    }

    return response;
  }
}

/// Builds prompts and routes to providers.
class AskAltuOrchestrator {
  AskAltuOrchestrator({
    IntentRouter? router,
    ContextShardBuilder? shardBuilder,
    ResponseGuard? guard,
    AIServiceManager? aiManager,
  })  : _router = router ?? const IntentRouter(),
        _shardBuilder = shardBuilder ?? const ContextShardBuilder(),
        _guard = guard ?? const ResponseGuard(),
        _aiManager = aiManager ?? AIServiceManager.instance;

  final IntentRouter _router;
  final ContextShardBuilder _shardBuilder;
  final ResponseGuard _guard;
  final AIServiceManager _aiManager;

  Future<AIResponse> answer(
    String query,
    List<DailySummary> data,
    List<ChatMessage> messages,
  ) async {
    final range = _extractDateRange(query, data);
    final filteredData = range != null ? _filterByRange(data, range) : data;
    final dataForPrompt = filteredData.isNotEmpty ? filteredData : data;

    final intent = _router.route(query);
    final prompt = _buildPrompt(query, dataForPrompt, messages, intent, range);
    final raw = await _aiManager.getAltuResponseWithPrompt(query, prompt);
    final exactFact = _buildExactDayFact(range, dataForPrompt);
    final guarded = _guard.apply(
      raw.text,
      intent,
      exactFact: exactFact,
    );
    return AIResponse(
      text: guarded,
      provider: raw.provider,
      isBackup: raw.isBackup,
    );
  }

  AskAltuPrompt _buildPrompt(
    String query,
    List<DailySummary> data,
    List<ChatMessage> messages,
    AskAltuIntent intent,
    _DateRange? dateRange,
  ) {
    final shards = _shardBuilder.build(data);
    final sectionOrder =
        _intentSections[intent] ?? _intentSections[AskAltuIntent.general]!;
    final sectionContent = <String, String>{
      'Personal stats:': shards.stats,
      'Sleep focus:': shards.sleep,
      'Activity focus:': shards.activity,
      'Correlations:': shards.correlations,
      'Recent days:': shards.recency,
      'Recent table:': shards.recentTable,
      'Weekly rhythm:': shards.weekly,
      'App usage:': shards.appUsage,
      'Goals:': shards.goals,
      'Screen/app focus:': shards.appUsage,
    };

    final buffer = StringBuffer()
      ..writeln(shards.persona)
      ..writeln()
      ..writeln(
        'Always answer with: plain text (no markdown), 2-3 short paragraphs, end with a single actionable tip.',
      )
      ..writeln(
        'If the user asks about productivity, prioritize productivityMinutes over steps and screen time; use the date range they mention.',
      );

    for (final section in sectionOrder) {
      final content = sectionContent[section];
      if (content == null || content.isEmpty) continue;
      buffer
        ..writeln(section)
        ..writeln(content)
        ..writeln();
    }

    buffer
      ..writeln('User question: $query')
      ..writeln(
        dateRange == null
            ? 'Date filter: not provided; using all available days.'
            : 'Date filter applied: ${dateRange.start.toIso8601String().split("T").first} to ${dateRange.end.toIso8601String().split("T").first}.',
      )
      ..writeln('If data is limited, use the closest relevant signal instead of saying you lack data.')
      ..writeln('Keep numbers specific when available.');

    final history = _buildConversationHistory(messages);

    return AskAltuPrompt(
      systemInstruction: buffer.toString(),
      conversationHistory: history,
      temperature: _intentTemperatures[intent] ?? 0.8,
      maxTokens: 1500,
      intent: intent,
    );
  }

  List<Map<String, dynamic>> _buildConversationHistory(List<ChatMessage> messages) {
    // Drop greeting, keep last 3 exchanges to reduce token use.
    final convo = messages.where((m) => m.id != '1').toList();
    final trimmed = convo.length > 6 ? convo.sublist(convo.length - 6) : convo;

    return trimmed.map((m) {
      return {
        'role': m.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': m.text}
        ],
      };
    }).toList();
  }

  _DateRange? _extractDateRange(String query, List<DailySummary> data) {
    final monthMap = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };

    final regex = RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s+(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)', caseSensitive: false);
    final matches = regex.allMatches(query.toLowerCase()).toList();
    if (matches.isEmpty) return null;

    int? yearHint;
    if (data.isNotEmpty) {
      yearHint = DateTime.parse(data.last.date).year;
    }

    DateTime? parseMatch(RegExpMatch m) {
      final dayStr = m.group(1);
      final monthStr = m.group(2);
      if (dayStr == null || monthStr == null) return null;
      final month = monthMap[monthStr];
      if (month == null) return null;
      final day = int.parse(dayStr);
      final year = yearHint ?? DateTime.now().year;
      return DateTime(year, month, day);
    }

    final start = parseMatch(matches.first);
    final end = matches.length > 1 ? parseMatch(matches[1]) : start;
    if (start == null || end == null) return null;
    return _DateRange(start, end);
  }

  List<DailySummary> _filterByRange(List<DailySummary> data, _DateRange range) {
    final start = range.start.isBefore(range.end) ? range.start : range.end;
    final end = range.end.isAfter(range.start) ? range.end : range.start;
    return data.where((d) {
      final dt = DateTime.tryParse(d.date);
      if (dt == null) return false;
      return (dt.isAtSameMomentAs(start) || dt.isAfter(start)) &&
          (dt.isAtSameMomentAs(end) || dt.isBefore(end));
    }).toList();
  }

  String? _buildExactDayFact(_DateRange? range, List<DailySummary> data) {
    if (range == null) return null;
    if (range.start != range.end) return null; // only single-day facts

    final dateStr = range.start.toIso8601String().split('T').first;
    final day = data.firstWhere(
      (d) => d.date == dateStr,
      orElse: () => DailySummary.empty(dateStr),
    );

    if (day.date != dateStr || day.steps == 0 && day.sleepMinutes == 0 && day.workoutMinutes == 0) {
      return 'No data found for $dateStr.';
    }

    return '$dateStr → steps ${day.steps}, sleep ${day.sleepMinutes} min, workout ${day.workoutMinutes} min, energy ${day.activeEnergy} kcal, productivity ${day.productivityMinutes} min.';
  }
}

class _DateRange {
  _DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

const _intentSections = {
  AskAltuIntent.sleep: [
    'Sleep focus:',
    'Correlations:',
    'Recent days:',
    'Recent table:',
  ],
  AskAltuIntent.activity: [
    'Activity focus:',
    'Personal stats:',
    'Recent days:',
    'Weekly rhythm:',
  ],
  AskAltuIntent.screenTime: [
    'Screen/app focus:',
    'Correlations:',
    'Recent days:',
    'App usage:',
  ],
  AskAltuIntent.correlations: [
    'Correlations:',
    'Personal stats:',
    'Recent table:',
  ],
  AskAltuIntent.goals: [
    'Goals:',
    'Personal stats:',
    'Recent days:',
  ],
  AskAltuIntent.general: [
    'Personal stats:',
    'Correlations:',
    'Recent days:',
  ],
};

const _intentTemperatures = {
  AskAltuIntent.sleep: 0.7,
  AskAltuIntent.activity: 0.7,
  AskAltuIntent.screenTime: 0.8,
  AskAltuIntent.correlations: 0.65,
  AskAltuIntent.goals: 0.7,
  AskAltuIntent.general: 0.8,
};

