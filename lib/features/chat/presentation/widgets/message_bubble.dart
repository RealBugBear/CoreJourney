import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isModerator,
    this.onDeleteRequested,
    this.onAcceptCall,
    this.onProposeAppointment,
  });

  final ChatMessage message;
  final bool isModerator;
  final VoidCallback? onDeleteRequested;
  final VoidCallback? onAcceptCall;
  final VoidCallback? onProposeAppointment;

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    final isOwn = message.isOwnMessage(currentUserId);

    if (message.isDeleted) return _DeletedBubble(isOwn: isOwn);
    if (message.isBotResponse) return _BotBubble(message: message);
    if (message.isCallRequest) return _CallRequestBubble(
      isOwn: isOwn,
      onAccept: isModerator ? onAcceptCall : null,
      onProposeAppointment: isModerator ? onProposeAppointment : null,
    );

    final theme = Theme.of(context);
    final canDelete = isOwn || isModerator;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: canDelete ? onDeleteRequested : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74),
          decoration: BoxDecoration(
            color: isOwn
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isOwn ? 16 : 4),
              bottomRight: Radius.circular(isOwn ? 4 : 16),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isOwn
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat.Hm().format(message.createdAt.toLocal()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isOwn
                      ? Colors.white.withValues(alpha: 0.65)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.isOwn});
  final bool isOwn;

  @override
  Widget build(BuildContext context) => Align(
    alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        'Diese Nachricht wurde entfernt.',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
      ),
    ),
  );
}

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(Icons.smart_toy_outlined,
                  size: 13,
                  color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 4),
              Text(
                'CoreJourney Assistent',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _CallRequestBubble extends StatelessWidget {
  const _CallRequestBubble({
    required this.isOwn,
    this.onAccept,
    this.onProposeAppointment,
  });
  final bool isOwn;
  final VoidCallback? onAccept;
  final VoidCallback? onProposeAppointment;

  @override
  Widget build(BuildContext context) {
    final showActions = !isOwn && (onAccept != null || onProposeAppointment != null);

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_outlined, color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  isOwn
                      ? 'Call-Anfrage gesendet'
                      : 'Klient möchte einen Video-Call',
                  style: TextStyle(
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onAccept != null)
                    FilledButton.tonal(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade100,
                        foregroundColor: Colors.teal.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Annehmen', style: TextStyle(fontSize: 12)),
                    ),
                  if (onAccept != null && onProposeAppointment != null)
                    const SizedBox(width: 8),
                  if (onProposeAppointment != null)
                    OutlinedButton(
                      onPressed: onProposeAppointment,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade900,
                        side: BorderSide(color: Colors.teal.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Termin', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
