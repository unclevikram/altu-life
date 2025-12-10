import 'dart:developer' as developer;

import 'package:altu_life/providers/health_providers.dart';
import 'package:altu_life/services/ask_altu_orchestrator.dart';
import 'package:altu_life/services/ai_service_manager.dart';
import 'package:altu_life/services/gemini_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat message model.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
  });

  final String id;
  final MessageRole role;
  final String text;
}

/// Message role (user or model).
enum MessageRole { user, model }

/// Chat state.
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Chat state notifier.
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(_initialState);

  final Ref _ref;
  final AskAltuOrchestrator _orchestrator = AskAltuOrchestrator();

  static const _initialState = ChatState(
    messages: [
      ChatMessage(
        id: '1',
        role: MessageRole.model,
        text:
            "Hi! I'm Altu, your personal health coach. I've analyzed your patterns and I'm ready to help! Ask me anything about your sleep, workouts, screen time, or how to optimize your habits. 💚",
      ),
    ],
  );

  /// Sends a message and gets a response from Gemini.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    developer.log(
      '📤 Sending message to Gemini',
      name: 'ChatProvider',
      error: 'User query: $text',
    );

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      text: text.trim(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final aiManager = AIServiceManager.instance;

      if (!aiManager.hasAnyProvider) {
        developer.log(
          '⚠️ No AI providers configured',
          name: 'ChatProvider',
          level: 900,
        );
        _addModelMessage(
          'Please configure at least one AI provider to chat with Altu.\n\n'
          'Add one of these to your .env file:\n'
          '- GEMINI_API_KEY (get from https://aistudio.google.com/app/apikey)\n'
          '- OPENAI_API_KEY (get from https://platform.openai.com/api-keys)',
        );
        return;
      }

      final dataContext = _ref.read(allTimeDataProvider);
      developer.log(
        '📊 Data context loaded: ${dataContext.length} days',
        name: 'ChatProvider',
      );
      final response = await _orchestrator.answer(
        text,
        dataContext,
        state.messages,
      );

      developer.log(
        '✅ Received response from ${response.provider.name}${response.isBackup ? " (backup)" : ""}',
        name: 'ChatProvider',
        error: 'Response length: ${response.text.length} characters',
      );

      _addModelMessage(response.text);
    } catch (e, stackTrace) {
      // Detailed error logging
      developer.log(
        '❌ Error in AI chat',
        name: 'ChatProvider',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // Severe
      );

      // Print to console in debug mode
      if (kDebugMode) {
        print('\n🚨 === AI SERVICE ERROR DEBUG INFO ===');
        print('Error Type: ${e.runtimeType}');
        print('Error Message: $e');
        print('Stack Trace:\n$stackTrace');
        print('======================================\n');
      }

      // Show user-friendly error messages
      String errorMessage;

      if (e is AIServiceException) {
        // AIServiceManager already provides good error messages
        errorMessage = e.message;
      } else if (e is GeminiException && e.message.contains('429')) {
        // Rate limit error (all retries exhausted)
        errorMessage = "I'm thinking too fast! The API rate limit was reached even after retries. Please wait a minute and try again.";
      } else if (e is GeminiException && e.message.contains('quota')) {
        // Quota exceeded
        errorMessage = "The API usage limit has been reached. Please check your Gemini API quota at https://ai.dev/usage";
      } else if (kDebugMode) {
        // Detailed error in debug mode
        errorMessage = "❌ Error: ${e.toString()}\n\nCheck the console for full details.";
      } else {
        // Generic error in release mode
        errorMessage = "Sorry, I encountered an issue. Please try again in a moment.";
      }

      _addModelMessage(errorMessage);
    }
  }

  void _addModelMessage(String text) {
    final modelMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: MessageRole.model,
      text: text,
    );

    state = state.copyWith(
      messages: [...state.messages, modelMessage],
      isLoading: false,
    );
  }

  /// Clears the chat history and resets to initial state.
  void clearChat() {
    developer.log('🔄 Clearing chat history', name: 'ChatProvider');
    state = _initialState;
    AIServiceManager.instance.resetContext();
  }
}

/// Chat notifier provider.
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
