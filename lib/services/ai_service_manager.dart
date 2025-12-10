import 'dart:developer' as developer;

import 'package:altu_life/data/models/models.dart';
import 'package:altu_life/services/ask_altu_orchestrator.dart';
import 'package:altu_life/services/gemini_service.dart';
import 'package:altu_life/services/openai_service.dart';
import 'package:flutter/foundation.dart';

/// Response from AI service with metadata about which service was used.
class AIResponse {
  const AIResponse({
    required this.text,
    required this.provider,
    this.isBackup = false,
  });

  final String text;
  final AIProvider provider;
  final bool isBackup;
}

/// Available AI providers.
enum AIProvider {
  gemini,
  openai,
}

/// Manages AI service calls with automatic fallback logic.
///
/// Tries Gemini first (primary), falls back to OpenAI if Gemini fails.
/// This ensures the chat always has a working AI provider.
class AIServiceManager {
  AIServiceManager._();

  static final AIServiceManager instance = AIServiceManager._();

  final _gemini = GeminiService.instance;
  final _openai = OpenAIService.instance;

  /// Checks if at least one AI provider is configured.
  bool get hasAnyProvider {
    return _gemini.isConfigured || _openai.isConfigured;
  }

  /// Checks which providers are configured.
  List<AIProvider> get configuredProviders {
    final providers = <AIProvider>[];
    if (_gemini.isConfigured) providers.add(AIProvider.gemini);
    if (_openai.isConfigured) providers.add(AIProvider.openai);
    return providers;
  }

  /// Resets cached context for all providers.
  void resetContext() {
    _gemini.resetContext();
    _openai.resetContext();
  }

  /// Gets a response from AI with automatic fallback.
  ///
  /// Tries providers in order:
  /// 1. Gemini (primary)
  /// 2. OpenAI (backup)
  ///
  /// Returns [AIResponse] with the text and which provider was used.
  Future<AIResponse> getAltuResponse(
    String query,
    List<DailySummary> dataContext, {
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    if (!hasAnyProvider) {
      throw AIServiceException(
        'No AI providers are configured. Please add GEMINI_API_KEY or OPENAI_API_KEY to your .env file.',
      );
    }

    developer.log(
      '🤖 Starting AI request with fallback',
      name: 'AIServiceManager',
      error: 'Configured providers: ${configuredProviders.map((p) => p.name).join(", ")}',
    );

    // Try Gemini first (primary)
    if (_gemini.isConfigured) {
      try {
        developer.log(
          '🔵 Trying primary provider: Gemini',
          name: 'AIServiceManager',
        );

        final response = await _gemini.getAltuResponse(
          query,
          dataContext,
          conversationHistory: conversationHistory,
        );

        developer.log(
          '✅ Gemini succeeded',
          name: 'AIServiceManager',
          error: 'Response length: ${response.length} chars',
        );

        return AIResponse(
          text: response,
          provider: AIProvider.gemini,
          isBackup: false,
        );
      } catch (e, stackTrace) {
        developer.log(
          '⚠️ Gemini failed, trying backup',
          name: 'AIServiceManager',
          error: e,
          stackTrace: stackTrace,
          level: 900,
        );

        if (kDebugMode) {
          print('\n⚠️ === GEMINI FAILED, TRYING BACKUP ===');
          print('Error: $e');
          print('========================================\n');
        }

        // If OpenAI is configured, try it as backup
        if (_openai.isConfigured) {
          try {
            developer.log(
              '🟢 Trying backup provider: OpenAI',
              name: 'AIServiceManager',
            );

            final response = await _openai.getAltuResponse(
              query,
              dataContext,
              conversationHistory: conversationHistory,
            );

            developer.log(
              '✅ OpenAI (backup) succeeded',
              name: 'AIServiceManager',
              error: 'Response length: ${response.length} chars',
            );

            return AIResponse(
              text: response,
              provider: AIProvider.openai,
              isBackup: true,
            );
          } catch (backupError, backupStackTrace) {
            developer.log(
              '❌ Both providers failed',
              name: 'AIServiceManager',
              error: 'Primary (Gemini): $e\nBackup (OpenAI): $backupError',
              stackTrace: backupStackTrace,
              level: 1000,
            );

            if (kDebugMode) {
              print('\n🚨 === BOTH PROVIDERS FAILED ===');
              print('Gemini error: $e');
              print('OpenAI error: $backupError');
              print('=================================\n');
            }

            // Both failed, throw combined error
            throw AIServiceException(
              'All AI providers failed.\n\nGemini: ${_getErrorMessage(e)}\n\nOpenAI: ${_getErrorMessage(backupError)}',
            );
          }
        } else {
          // No backup configured, rethrow original error
          rethrow;
        }
      }
    }

    // If Gemini is not configured, try OpenAI directly
    if (_openai.isConfigured) {
      try {
        developer.log(
          '🟢 Using OpenAI (Gemini not configured)',
          name: 'AIServiceManager',
        );

        final response = await _openai.getAltuResponse(
          query,
          dataContext,
          conversationHistory: conversationHistory,
        );

        developer.log(
          '✅ OpenAI succeeded',
          name: 'AIServiceManager',
          error: 'Response length: ${response.length} chars',
        );

        return AIResponse(
          text: response,
          provider: AIProvider.openai,
          isBackup: false,
        );
      } catch (e, stackTrace) {
        developer.log(
          '❌ OpenAI failed',
          name: 'AIServiceManager',
          error: e,
          stackTrace: stackTrace,
          level: 1000,
        );

        rethrow;
      }
    }

    // Should never reach here due to hasAnyProvider check at start
    throw AIServiceException('No AI providers available.');
  }

  /// Extracts a clean error message from an exception.
  String _getErrorMessage(dynamic error) {
    if (error is GeminiException) {
      if (error.message.contains('429')) {
        return 'Rate limit exceeded';
      } else if (error.message.contains('quota')) {
        return 'Quota exceeded';
      } else if (error.message.contains('API Key')) {
        return 'API key invalid';
      }
      return error.message;
    } else if (error is OpenAIException) {
      if (error.message.contains('429')) {
        return 'Rate limit exceeded';
      } else if (error.message.contains('quota')) {
        return 'Quota exceeded';
      } else if (error.message.contains('API Key')) {
        return 'API key invalid';
      }
      return error.message;
    }
    return error.toString();
  }

  /// Gets a response using a prebuilt prompt (system + trimmed history).
  ///
  /// This path is used by AskAltuOrchestrator to keep prompts small and
  /// intent-aware while still leveraging provider fallback.
  Future<AIResponse> getAltuResponseWithPrompt(
    String query,
    AskAltuPrompt prompt,
  ) async {
    if (!hasAnyProvider) {
      throw AIServiceException(
        'No AI providers are configured. Please add GEMINI_API_KEY or OPENAI_API_KEY to your .env file.',
      );
    }

    developer.log(
      '🤖 Starting AI request with orchestrated prompt',
      name: 'AIServiceManager',
      error: 'Intent: ${prompt.intent.name}, Configured: ${configuredProviders.map((p) => p.name).join(", ")}',
    );

    // Try Gemini first (primary)
    if (_gemini.isConfigured) {
      try {
        developer.log(
          '🔵 Trying primary provider: Gemini (orchestrated)',
          name: 'AIServiceManager',
        );

        final response = await _gemini.getAltuResponseWithInstruction(
          query,
          prompt.systemInstruction,
          conversationHistory: prompt.conversationHistory,
          temperature: prompt.temperature,
          maxTokens: prompt.maxTokens,
        );

        developer.log(
          '✅ Gemini succeeded',
          name: 'AIServiceManager',
          error: 'Response length: ${response.length} chars',
        );

        return AIResponse(
          text: response,
          provider: AIProvider.gemini,
          isBackup: false,
        );
      } catch (e, stackTrace) {
        developer.log(
          '⚠️ Gemini failed, trying backup',
          name: 'AIServiceManager',
          error: e,
          stackTrace: stackTrace,
          level: 900,
        );

        if (kDebugMode) {
          print('\n⚠️ === GEMINI FAILED, TRYING BACKUP ===');
          print('Error: $e');
          print('========================================\n');
        }

        if (_openai.isConfigured) {
          try {
            developer.log(
              '🟢 Trying backup provider: OpenAI (orchestrated)',
              name: 'AIServiceManager',
            );

            final response = await _openai.getAltuResponseWithInstruction(
              query,
              prompt.systemInstruction,
              conversationHistory: prompt.conversationHistory,
              temperature: prompt.temperature,
              maxTokens: prompt.maxTokens,
            );

            developer.log(
              '✅ OpenAI (backup) succeeded',
              name: 'AIServiceManager',
              error: 'Response length: ${response.length} chars',
            );

            return AIResponse(
              text: response,
              provider: AIProvider.openai,
              isBackup: true,
            );
          } catch (backupError, backupStackTrace) {
            developer.log(
              '❌ Both providers failed (orchestrated)',
              name: 'AIServiceManager',
              error: 'Primary (Gemini): $e\nBackup (OpenAI): $backupError',
              stackTrace: backupStackTrace,
              level: 1000,
            );
            throw AIServiceException(
              'All AI providers failed.\n\nGemini: ${_getErrorMessage(e)}\n\nOpenAI: ${_getErrorMessage(backupError)}',
            );
          }
        } else {
          rethrow;
        }
      }
    }

    // Gemini not configured; try OpenAI directly
    if (_openai.isConfigured) {
      try {
        developer.log(
          '🟢 Using OpenAI (Gemini not configured, orchestrated)',
          name: 'AIServiceManager',
        );

        final response = await _openai.getAltuResponseWithInstruction(
          query,
          prompt.systemInstruction,
          conversationHistory: prompt.conversationHistory,
          temperature: prompt.temperature,
          maxTokens: prompt.maxTokens,
        );

        developer.log(
          '✅ OpenAI succeeded',
          name: 'AIServiceManager',
          error: 'Response length: ${response.length} chars',
        );

        return AIResponse(
          text: response,
          provider: AIProvider.openai,
          isBackup: false,
        );
      } catch (e, stackTrace) {
        developer.log(
          '❌ OpenAI failed (orchestrated)',
          name: 'AIServiceManager',
          error: e,
          stackTrace: stackTrace,
          level: 1000,
        );

        throw AIServiceException(_getErrorMessage(e));
      }
    }

    throw AIServiceException('No AI providers available.');
  }
}

/// Exception thrown when AI service operations fail.
class AIServiceException implements Exception {
  AIServiceException(this.message);

  final String message;

  @override
  String toString() => 'AIServiceException: $message';
}
