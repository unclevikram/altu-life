import 'dart:convert';
import 'dart:developer' as developer;

import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/services/ai_context_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with the OpenAI API (ChatGPT).
///
/// This service acts as a backup for Gemini when it fails.
/// Maintains chat context similar to GeminiService.
class OpenAIService {
  OpenAIService._();

  static final OpenAIService instance = OpenAIService._();

  /// Default model to use (gpt-4o-mini is cost-effective and fast)
  static const String _defaultModel = 'gpt-4o-mini';

  /// Maximum retry attempts for rate limit errors
  static const int _maxRetries = 2;

  /// Base delay in seconds for exponential backoff
  static const int _baseDelaySeconds = 5;

  /// Base URL for OpenAI API
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Cached comprehensive data context (set once on first message)
  String? _cachedDataContext;

  /// Gets the API key from environment variables.
  String? get apiKey => dotenv.env['OPENAI_API_KEY'];

  /// Gets the preferred model from environment or uses default
  String get model => dotenv.env['OPENAI_MODEL'] ?? _defaultModel;

  /// Checks if the API key is configured and valid.
  bool get isConfigured {
    final key = apiKey;
    return key != null &&
        key.isNotEmpty &&
        key != 'your_openai_api_key_here';
  }

  /// Resets the cached data context (useful when data changes).
  void resetContext() {
    _cachedDataContext = null;
  }

  /// Creates a comprehensive data summary with all key metrics and correlations.
  ///
  /// This is sent ONCE at the beginning of the chat session and cached.
  String _buildComprehensiveContext(List<DailySummary> data) {
    if (_cachedDataContext != null) {
      developer.log(
        '📦 Using cached data context',
        name: 'OpenAIService',
      );
      return _cachedDataContext!;
    }

    _cachedDataContext = AIContextBuilder.buildDataContext(
      data,
      serviceName: 'OpenAIService',
    );

    return _cachedDataContext!;
  }

  /// Generates a response from OpenAI based on user query and health data.
  ///
  /// [query] - The user's question or message
  /// [dataContext] - The aggregated health data for context (used to build summary on first call)
  /// [conversationHistory] - Previous messages in the conversation for context
  ///
  /// Returns the AI-generated response text.
  Future<String> getAltuResponse(
    String query,
    List<DailySummary> dataContext, {
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    if (!isConfigured) {
      throw OpenAIException('OpenAI API Key is not configured.');
    }

    // Retry with exponential backoff on rate limit errors
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final isLastAttempt = attempt == _maxRetries - 1;

      try {
        if (attempt > 0) {
          final delaySeconds = _baseDelaySeconds * (1 << (attempt - 1)); // 5s, 10s
          developer.log(
            '🔄 Retry attempt $attempt after $delaySeconds second delay',
            name: 'OpenAIService',
          );
          await Future.delayed(Duration(seconds: delaySeconds));
        }

        return await _makeApiRequest(
          query,
          dataContext,
          conversationHistory: conversationHistory,
        );
      } catch (e) {
        if (e is OpenAIException && e.message.contains('429') && !isLastAttempt) {
          developer.log(
            '⚠️ Rate limit hit, will retry...',
            name: 'OpenAIService',
            level: 900,
          );
          continue; // Retry after delay
        }
        rethrow; // If not rate limit or last attempt, throw error
      }
    }

    throw OpenAIException('All retry attempts exhausted.');
  }

  /// Generates a response using a prebuilt system prompt (from orchestrator).
  Future<String> getAltuResponseWithInstruction(
    String query,
    String systemPrompt, {
    List<Map<String, dynamic>>? conversationHistory,
    double temperature = 0.8,
    int maxTokens = 1500,
  }) async {
    if (!isConfigured) {
      throw OpenAIException('OpenAI API Key is not configured.');
    }

    return _makeApiRequestWithInstruction(
      query: query,
      systemPrompt: systemPrompt,
      conversationHistory: conversationHistory,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// Makes the actual API request to OpenAI.
  Future<String> _makeApiRequest(
    String query,
    List<DailySummary> dataContext, {
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    final dataContextText = _buildComprehensiveContext(dataContext);

    final systemPrompt = '''
You are Altu, an empathetic, data-driven health assistant who makes personalized insights accessible and actionable.

**Your Mission:**
- Help users understand their health patterns through their data
- Provide specific, actionable recommendations based on ACTUAL data
- Always find something useful to say, even with limited information
- Be conversational, warm, and encouraging

**Core Principles:**
1. **Always Provide Value**: Even if you don't have perfect data, provide the best answer possible based on what you know
2. **Be Specific**: Use actual numbers from the data ("You sleep 11 minutes more after workouts" vs "Workouts help sleep")
3. **Celebrate Progress**: Highlight wins, streaks, and improvements
4. **Actionable Insights**: End with a concrete, achievable suggestion
5. **Privacy First**: Analysis is local, data never leaves the device
6. **No Judgment**: Frame everything as opportunities for growth

**How to Handle Questions:**

**When answering ANY question:**
- Search the data summary below for relevant patterns
- If exact data exists, cite it specifically
- If data is limited, provide the closest relevant insight
- Never say "I don't have that data" - always provide related information
- Format responses in 2-3 short paragraphs for readability

**For "What happens to my sleep when I work out?"**
→ Use Sleep After Workout data from the data summary below
→ Mention recovery sleep patterns if relevant

**For "What one thing could I change to sleep better?"**
→ Look at Sleep Correlations - find the strongest negative correlation (e.g., "Slack -0.55")
→ Suggest reducing that app before bed with specific time recommendation
→ If no strong correlations, suggest consistency improvements

**For "What am I doing really well?"**
→ Highlight Personal Bests, workout streaks, and positive patterns
→ Celebrate consistency scores if high
→ Mention any strong positive correlations

**For "Compare my weekday vs weekend habits"**
→ Use Weekend Sleep data and scan recent 30 days for patterns
→ Compare steps, screen time, sleep quality
→ Note any interesting differences

**For "Is there a connection between my screentime and energy levels?"**
→ Check Energy Correlations for app relationships
→ Look at entertainment vs productivity app usage
→ Provide specific correlation coefficients if available

**For "What questions can I ask?" or similar meta-questions:**
→ Suggest 5-7 specific data-driven questions they can explore, such as:
  - "How does my sleep quality change on workout days?"
  - "What's my best time of day for productivity?"
  - "Which apps correlate with my best sleep nights?"
  - "How consistent are my weekday habits?"
  - "What's my personal record for active calories?"
  - "Do I recover better on weekends?"
  - "Which day of the week am I most active?"
→ Encourage exploration and curiosity about their patterns

**For any other question:**
→ Search ALL sections of the data for relevant information
→ Provide the most helpful answer possible with what you have
→ If truly no data exists, offer related insights and suggest what to track

**Response Style:**
- Keep responses concise (2-3 paragraphs, max 4 for complex topics)
- Use natural language, avoid technical jargon
- Include specific numbers when available
- End with a friendly micro-challenge or encouragement
- IMPORTANT: Do NOT use markdown formatting (**, *, _, etc.) - use plain text only
- Use simple bullet points with dashes (-) if needed, but avoid asterisks

---

$dataContextText
''';
    return _makeApiRequestWithInstruction(
      query: query,
      systemPrompt: systemPrompt,
      conversationHistory: conversationHistory,
      temperature: 0.8,
      maxTokens: 2000,
      dataContextSize: dataContextText.length,
    );
  }

  Future<String> _makeApiRequestWithInstruction({
    required String query,
    required String systemPrompt,
    List<Map<String, dynamic>>? conversationHistory,
    double temperature = 0.8,
    int maxTokens = 1500,
    int? dataContextSize,
  }) async {
    final url = Uri.parse(_baseUrl);

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': systemPrompt,
      }
    ];

    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      for (final msg in conversationHistory) {
        messages.add({
          'role': msg['role'] == 'user' ? 'user' : 'assistant',
          'content': msg['parts'][0]['text'],
        });
      }
      developer.log(
        '💬 Including ${conversationHistory.length} conversation messages',
        name: 'OpenAIService',
      );
    }

    messages.add({
      'role': 'user',
      'content': query,
    });

    final requestBody = {
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'top_p': 0.95,
    };

    final requestBodyJson = jsonEncode(requestBody);

    developer.log(
      '🌐 Sending API request to OpenAI',
      name: 'OpenAIService',
      error: 'Model: $model\n'
          'URL: $_baseUrl\n'
          'Request body size: ${requestBodyJson.length} bytes\n'
          'System prompt size: ${systemPrompt.length} chars\n'
          'Data context size: ${dataContextSize ?? 0} chars',
    );

    if (kDebugMode) {
      print('\n📤 === OPENAI API REQUEST ===');
      print('Model: $model');
      print('Query: $query');
      print('Conversation history: ${conversationHistory?.length ?? 0} messages');
      print('Request body size: ${requestBodyJson.length} bytes');
      print('============================\n');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: requestBodyJson,
    );

    developer.log(
      '📥 Received API response',
      name: 'OpenAIService',
      error: 'Status: ${response.statusCode}\n'
          'Response size: ${response.body.length} bytes',
    );

    if (kDebugMode) {
      print('\n📥 === OPENAI API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response size: ${response.body.length} bytes');
      print('==============================\n');
    }

    if (response.statusCode != 200) {
      developer.log(
        '❌ API request failed',
        name: 'OpenAIService',
        error: 'Status: ${response.statusCode}\nBody: ${response.body}',
        level: 1000,
      );

      if (kDebugMode) {
        print('\n🚨 === OPENAI API ERROR RESPONSE ===');
        print('Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        print('=====================================\n');
      }

      throw OpenAIException(
        'API request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (kDebugMode) {
      print('\n📄 === RESPONSE JSON STRUCTURE ===');
      print('Keys: ${data.keys.toList()}');
      if (data.containsKey('choices')) {
        print('Choices count: ${(data['choices'] as List).length}');
      }
      print('===================================\n');
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      developer.log(
        '⚠️ No choices in response',
        name: 'OpenAIService',
        error: 'Response data: ${jsonEncode(data)}',
        level: 900,
      );

      if (kDebugMode) {
        print('\n⚠️ === NO CHOICES ERROR ===');
        print('Full response: ${jsonEncode(data)}');
        print('===============================\n');
      }

      throw OpenAIException('No response generated.');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    final finishReason = choices[0]['finish_reason'] as String?;
    developer.log(
      '🏁 Finish reason: $finishReason',
      name: 'OpenAIService',
    );

    if (finishReason == 'length') {
      developer.log(
        '⚠️ Response truncated due to max_tokens',
        name: 'OpenAIService',
        level: 900,
      );
    }

    if (content == null || content.isEmpty) {
      developer.log(
        '⚠️ Empty content in response',
        name: 'OpenAIService',
        error: 'Message: ${jsonEncode(message)}',
        level: 900,
      );

      if (kDebugMode) {
        print('\n⚠️ === EMPTY CONTENT ERROR ===');
        print('Message: ${jsonEncode(message)}');
        print('=========================\n');
      }

      throw OpenAIException('Empty response from API.');
    }

    developer.log(
      '✅ Successfully extracted response text',
      name: 'OpenAIService',
      error: 'Text length: ${content.length} characters',
    );

    return content;
  }
}

/// Exception thrown when OpenAI API operations fail.
class OpenAIException implements Exception {
  OpenAIException(this.message);

  final String message;

  @override
  String toString() => 'OpenAIException: $message';
}
