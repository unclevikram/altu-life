import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/features/ask_altu/presentation/providers/chat_provider.dart';
import 'package:altu_life/features/ask_altu/presentation/widgets/chat_bubble.dart';
import 'package:altu_life/features/ask_altu/presentation/widgets/suggestion_chip.dart';
import 'package:altu_life/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Ask Altu chat screen.
///
/// AI-powered health assistant using Gemini API.
class AskAltuScreen extends ConsumerStatefulWidget {
  const AskAltuScreen({super.key});

  @override
  ConsumerState<AskAltuScreen> createState() => _AskAltuScreenState();
}

class _AskAltuScreenState extends ConsumerState<AskAltuScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // Dynamic list of available suggestions
  final List<String> _availableSuggestions = [
    'What one thing could I change to sleep better?',
    'Compare my weekday vs weekend habits',
    'Is there a connection between my screentime and energy levels?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Add a small delay to ensure the loading bubble is rendered
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    _textController.clear();
    _focusNode.unfocus();

    // Remove the suggestion if it was from the pre-populated list
    if (_availableSuggestions.contains(text)) {
      setState(() {
        _availableSuggestions.remove(text);
      });
    }

    await ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final isApiConfigured = GeminiService.instance.isConfigured;

    // Scroll to bottom when messages change or loading state changes
    ref.listen(chatNotifierProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        // Chat Header
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 24,
            right: 24,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.slate100),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 20,
                  color: AppColors.brand600,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Altu Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                    ),
                  ),
                  Text(
                    'Your Personal Data Nerd • Private',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brand600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Messages Area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == chatState.messages.length && chatState.isLoading) {
                return const _LoadingBubble();
              }
              final message = chatState.messages[index];
              return ChatBubble(message: message);
            },
          ),
        ),

        // Input Area
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.slate100),
            ),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 80,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Suggestion Chips - wrapped layout (only show if suggestions available)
              if (_availableSuggestions.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSuggestions.map((s) {
                    return SuggestionChip(
                      text: s,
                      onTap: chatState.isLoading
                          ? null
                          : () => _sendMessage(s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Text Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: !chatState.isLoading,
                        decoration: const InputDecoration(
                          hintText: 'Ask about your best days...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.slate800,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (context, value, child) {
                        final canSend =
                            value.text.trim().isNotEmpty && !chatState.isLoading;
                        return GestureDetector(
                          onTap: canSend
                              ? () => _sendMessage(value.text)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: canSend
                                  ? AppColors.brand600
                                  : AppColors.slate300,
                              shape: BoxShape.circle,
                              boxShadow: canSend
                                  ? [
                                      BoxShadow(
                                        color: AppColors.brand600
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              LucideIcons.send,
                              size: 16,
                              color: canSend
                                  ? Colors.white
                                  : AppColors.slate500,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // API Key Warning
              if (!isApiConfigured)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.amber50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 12,
                          color: AppColors.amber600,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'API Key not found. Chat requires a valid key. Dashboard still works.',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.amber600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Loading indicator bubble.
class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.brand500,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.bot,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.slate100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (i * 150)),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.slate400
                            .withValues(alpha: 0.5 + (value * 0.5)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

