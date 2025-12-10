import 'dart:convert';
import 'dart:developer' as developer;

import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/services/ai_context_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with the Gemini AI API.
///
/// This service handles all communication with Google's Gemini API
/// for the Ask Altu chat feature. Maintains chat context to avoid
/// resending data repeatedly.
class GeminiService {
  GeminiService._();

  static final GeminiService instance = GeminiService._();

  /// Primary Gemini model to use
  static const String _primaryModel = 'gemini-2.5-flash';

  /// Maximum retry attempts for rate limit errors (reduced for fast failover to OpenAI)
  static const int _maxRetries = 2;

  /// Base delay in seconds for exponential backoff (reduced for fast failover)
  static const int _baseDelaySeconds = 2;

  /// Base URL for Gemini API
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Cached comprehensive data context (set once on first message)
  String? _cachedDataContext;

  /// Gets the API key from environment variables.
  String? get apiKey => dotenv.env['GEMINI_API_KEY'];

  /// Checks if the API key is configured and valid.
  bool get isConfigured {
    final key = apiKey;
    return key != null &&
        key.isNotEmpty &&
        key != 'your_gemini_api_key_here';
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
        name: 'GeminiService',
      );
      return _cachedDataContext!;
    }

    _cachedDataContext = AIContextBuilder.buildDataContext(
      data,
      serviceName: 'GeminiService',
    );

    return _cachedDataContext!;
  }

  /// Generates a response from Altu based on user query and health data.
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
      throw GeminiException('API Key is not configured.');
    }

    // Retry with exponential backoff on rate limit errors
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final isLastAttempt = attempt == _maxRetries - 1;

      try {
        if (attempt > 0) {
          final delaySeconds = _baseDelaySeconds * (1 << (attempt - 1)); // 2s, 4s
          developer.log(
            '🔄 Retry attempt $attempt after $delaySeconds second delay',
            name: 'GeminiService',
          );
          await Future.delayed(Duration(seconds: delaySeconds));
        }

        return await _makeApiRequest(
          query,
          dataContext,
          conversationHistory: conversationHistory,
          modelName: _primaryModel,
        );
      } catch (e) {
        if (e is GeminiException && e.message.contains('429') && !isLastAttempt) {
          developer.log(
            '⚠️ Rate limit hit, will retry...',
            name: 'GeminiService',
            level: 900,
          );
          continue; // Retry after delay
        }
        rethrow; // If not rate limit or last attempt, throw error
      }
    }

    throw GeminiException('All retry attempts exhausted.');
  }

  /// Generates a response using a prebuilt system instruction (from orchestrator).
  Future<String> getAltuResponseWithInstruction(
    String query,
    String systemInstruction, {
    List<Map<String, dynamic>>? conversationHistory,
    double temperature = 0.8,
    int maxTokens = 1024,
  }) async {
    if (!isConfigured) {
      throw GeminiException('API Key is not configured.');
    }

    return _makeApiRequestWithInstruction(
      query: query,
      systemInstruction: systemInstruction,
      conversationHistory: conversationHistory,
      modelName: _primaryModel,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// Makes the actual API request to Gemini.
  Future<String> _makeApiRequest(
    String query,
    List<DailySummary> dataContext, {
    List<Map<String, dynamic>>? conversationHistory,
    required String modelName,
  }) async {
    final dataContextText = _buildComprehensiveContext(dataContext);

    final systemInstruction = '''
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
      systemInstruction: systemInstruction,
      conversationHistory: conversationHistory,
      modelName: modelName,
      temperature: 0.8,
      maxTokens: 8192,
      dataContextSize: dataContextText.length,
    );
  }

  Future<String> _makeApiRequestWithInstruction({
    required String query,
    required String systemInstruction,
    required String modelName,
    List<Map<String, dynamic>>? conversationHistory,
    double temperature = 0.8,
    int maxTokens = 1024,
    int? dataContextSize,
  }) async {
    final url = Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey');

    final contents = <Map<String, dynamic>>[];

    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      contents.addAll(conversationHistory);
      developer.log(
        '💬 Including ${conversationHistory.length} conversation messages',
        name: 'GeminiService',
      );
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': query}
      ],
    });

    final requestBody = {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
        'topP': 0.95,
      },
    };

    final requestBodyJson = jsonEncode(requestBody);

    developer.log(
      '🌐 Sending API request to Gemini',
      name: 'GeminiService',
      error: 'Model: $modelName\n'
          'URL: $_baseUrl/$modelName:generateContent\n'
          'Request body size: ${requestBodyJson.length} bytes\n'
          'System instruction size: ${systemInstruction.length} chars\n'
          'Data context size: ${dataContextSize ?? 0} chars',
    );

    if (kDebugMode) {
      print('\n📤 === GEMINI API REQUEST ===');
      print('Model: $modelName');
      print('Query: $query');
      print('Conversation history: ${conversationHistory?.length ?? 0} messages');
      print('Request body size: ${requestBodyJson.length} bytes');
      print('============================\n');
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBodyJson,
    );

    developer.log(
      '📥 Received API response',
      name: 'GeminiService',
      error: 'Status: ${response.statusCode}\n'
          'Response size: ${response.body.length} bytes',
    );

    if (kDebugMode) {
      print('\n📥 === GEMINI API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response size: ${response.body.length} bytes');
      print('==============================\n');
    }

    if (response.statusCode != 200) {
      developer.log(
        '❌ API request failed',
        name: 'GeminiService',
        error: 'Status: ${response.statusCode}\nBody: ${response.body}',
        level: 1000,
      );

      if (kDebugMode) {
        print('\n🚨 === GEMINI API ERROR RESPONSE ===');
        print('Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        print('=====================================\n');
      }

      throw GeminiException(
        'API request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (kDebugMode) {
      print('\n📄 === RESPONSE JSON STRUCTURE ===');
      print('Keys: ${data.keys.toList()}');
      if (data.containsKey('candidates')) {
        print('Candidates count: ${(data['candidates'] as List).length}');
      }
      print('===================================\n');
    }

    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      developer.log(
        '⚠️ No candidates in response',
        name: 'GeminiService',
        error: 'Response data: ${jsonEncode(data)}',
        level: 900,
      );

      if (kDebugMode) {
        print('\n⚠️ === NO CANDIDATES ERROR ===');
        print('Full response: ${jsonEncode(data)}');
        print('===============================\n');
      }

      throw GeminiException('No response generated.');
    }

    final finishReason = candidates[0]['finishReason'] as String?;
    developer.log(
      '🏁 Finish reason: $finishReason',
      name: 'GeminiService',
    );

    if (finishReason == 'MAX_TOKENS') {
      developer.log(
        '⚠️ Response truncated due to MAX_TOKENS',
        name: 'GeminiService',
        level: 900,
      );
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;

    if (parts == null || parts.isEmpty) {
      developer.log(
        '⚠️ No parts in candidate content',
        name: 'GeminiService',
        error: 'Content: ${jsonEncode(content)}',
        level: 900,
      );

      if (kDebugMode) {
        print('\n⚠️ === NO PARTS ERROR ===');
        print('Candidate content: ${jsonEncode(content)}');
        print('=========================\n');
      }

      throw GeminiException('Empty response from API.');
    }

    final text = parts[0]['text'] as String?;

    developer.log(
      '✅ Successfully extracted response text',
      name: 'GeminiService',
      error: 'Text length: ${text?.length ?? 0} characters',
    );

    return text ?? "I'm having trouble thinking right now. Try again?";
  }
}

/// Exception thrown when Gemini API operations fail.
class GeminiException implements Exception {
  GeminiException(this.message);

  final String message;

  @override
  String toString() => 'GeminiException: $message';
}
