import 'package:altu_life/app/theme/app_colors.dart';
import 'package:altu_life/features/ask_altu/presentation/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Chat message bubble.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  bool get isUser => message.role == MessageRole.user;

  /// Cleans markdown formatting from text if present.
  String _cleanMarkdown(String text) {
    return text
        // Remove bold markers
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        // Remove italic markers
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        // Remove underscores
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1')
        // Clean up any remaining double asterisks
        .replaceAll('**', '')
        .replaceAll('__', '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
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
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.slate800 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: isUser
                      ? const Radius.circular(16)
                      : Radius.zero,
                  topRight: isUser
                      ? Radius.zero
                      : const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                _cleanMarkdown(message.text),
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppColors.slate700,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.user,
                size: 16,
                color: AppColors.slate600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

