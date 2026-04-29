import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../chat/domain/models/chat_message.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../domain/models/video_call.dart';
import '../providers/video_providers.dart';
import '../screens/video_call_screen.dart';

class IncomingCallListener extends ConsumerStatefulWidget {
  const IncomingCallListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingCallListener> createState() =>
      _IncomingCallListenerState();
}

class _IncomingCallListenerState extends ConsumerState<IncomingCallListener> {
  static const _staleCallAge = Duration(minutes: 2);
  static const _staleCallRequestAge = Duration(minutes: 5);

  final Set<String> _knownCallIds = <String>{};
  final Set<String> _knownCallRequestIds = <String>{};
  bool _dialogOpen = false;
  ProviderSubscription<AsyncValue<List<VideoCall>>>? _callsSubscription;
  ProviderSubscription<AsyncValue<List<ChatMessage>>>?
      _callRequestsSubscription;

  @override
  void initState() {
    super.initState();
    _callsSubscription = ref.listenManual<AsyncValue<List<VideoCall>>>(
      activeCallsProvider,
      (_, next) => _handleActiveCalls(next.valueOrNull ?? const []),
      fireImmediately: true,
    );
    _callRequestsSubscription = ref.listenManual<AsyncValue<List<ChatMessage>>>(
      callRequestsProvider,
      (_, next) => _handleCallRequests(next.valueOrNull ?? const []),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _callsSubscription?.close();
    _callRequestsSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeCallsProvider);
    ref.watch(callRequestsProvider);

    return widget.child;
  }

  void _handleActiveCalls(List<VideoCall> calls) {
    for (final call in calls) {
      _handleActiveCall(call);
    }
  }

  void _handleCallRequests(List<ChatMessage> requests) {
    for (final request in requests) {
      _handleCallRequest(request);
    }
  }

  void _handleActiveCall(VideoCall? call) {
    if (call == null) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (call.startedBy == currentUserId) return;

    final callAge = DateTime.now().difference(call.startedAt);
    if (callAge > _staleCallAge) {
      _knownCallIds.add(call.id);
      unawaited(ref.read(endCallProvider.notifier).end(call.id));
      return;
    }

    if (!_knownCallIds.add(call.id)) return;
    if (_dialogOpen || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dialogOpen && mounted) {
        _showIncomingCall(context, call);
      }
    });
  }

  void _handleCallRequest(ChatMessage request) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (request.senderId == currentUserId) return;

    final requestAge = DateTime.now().difference(request.createdAt);
    if (requestAge > _staleCallRequestAge) {
      _knownCallRequestIds.add(request.id);
      return;
    }

    if (!_knownCallRequestIds.add(request.id)) return;
    if (_dialogOpen || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dialogOpen && mounted) {
        _showCallRequest(context, request);
      }
    });
  }

  Future<void> _showIncomingCall(BuildContext context, VideoCall call) async {
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Eingehender Video-Call'),
        content: const Text(
          'Dein Trainer startet gerade einen Video-Call.\nMöchtest du beitreten?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ignorieren'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openVideoCall(context, ref, call);
            },
            child: const Text('Beitreten'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _showCallRequest(
    BuildContext context,
    ChatMessage request,
  ) async {
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Video-Call angefragt'),
        content: const Text(
          'Dein Klient fragt einen Video-Call an.\nMöchtest du den Call jetzt starten?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Später'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _startRequestedCall(context, request.channelId);
            },
            child: const Text('Call starten'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _startRequestedCall(
    BuildContext context,
    String channelId,
  ) async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final cameraOk = statuses[Permission.camera]?.isGranted ?? false;
    final micOk = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraOk || !micOk) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kamera & Mikrofon-Zugriff erforderlich. Bitte in den Einstellungen erlauben.',
          ),
        ),
      );
      return;
    }

    final call = await ref.read(startCallProvider.notifier).start(channelId);
    if (call == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call konnte nicht gestartet werden.')),
      );
      return;
    }

    if (!context.mounted) return;
    await openVideoCall(context, ref, call);
  }
}

Future<void> openVideoCall(
  BuildContext context,
  WidgetRef ref,
  VideoCall call,
) async {
  final uid = localAgoraUid();
  final token = await ref
      .read(videoRepositoryProvider)
      .getAgoraToken(call.channelId, call.agoraChannelName, uid: uid);

  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => VideoCallScreen(
        call: call,
        token: token,
        localUid: uid,
      ),
    ),
  );
}

int localAgoraUid() {
  final id =
      (Supabase.instance.client.auth.currentUser?.id ?? '').replaceAll('-', '');
  final first = id.length >= 8 ? id.substring(0, 8) : id.padRight(8, '0');
  final parsed = int.tryParse(first, radix: 16) ?? 1;
  return (parsed & 0x7fffffff).clamp(1, 2147483647);
}
