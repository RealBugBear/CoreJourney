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
  VideoCall? _incomingCall;
  ChatMessage? _incomingRequest;
  bool _joining = false;
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

    final call = _incomingCall;
    final request = _incomingRequest;

    return Stack(
      children: [
        widget.child,
        if (call != null || request != null)
          _IncomingCallWindow(
            isJoining: _joining,
            title: call != null
                ? 'Eingehender Video-Call'
                : 'Video-Call angefragt',
            message: call != null
                ? 'Ein Video-Call wurde gestartet. Du kannst direkt beitreten.'
                : 'Ein Klient fragt einen Video-Call an. Du kannst den Call jetzt starten.',
            primaryLabel: call != null ? 'Beitreten' : 'Call starten',
            secondaryLabel: call != null ? 'Ignorieren' : 'Später',
            onPrimary: () async {
              if (call != null) {
                await _joinIncomingCall(call);
              } else if (request != null) {
                await _startRequestedCall(context, request.channelId);
              }
            },
            onSecondary: _dismissIncomingWindow,
          ),
      ],
    );
  }

  void _handleActiveCalls(List<VideoCall> calls) {
    final visibleCallIds = calls.map((call) => call.id).toSet();
    if (_incomingCall != null && !visibleCallIds.contains(_incomingCall!.id)) {
      setState(() => _incomingCall = null);
    }

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
    if (!mounted || _incomingCall != null || _incomingRequest != null) return;

    setState(() => _incomingCall = call);
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
    if (!mounted || _incomingCall != null || _incomingRequest != null) return;

    setState(() => _incomingRequest = request);
  }

  void _dismissIncomingWindow() {
    if (!mounted) return;
    setState(() {
      _incomingCall = null;
      _incomingRequest = null;
      _joining = false;
    });
  }

  Future<void> _joinIncomingCall(VideoCall call) async {
    if (_joining) return;
    setState(() => _joining = true);
    await openVideoCall(context, ref, call);
    _dismissIncomingWindow();
  }

  Future<void> _startRequestedCall(
    BuildContext context,
    String channelId,
  ) async {
    if (_joining) return;
    setState(() => _joining = true);
    final statuses = await [Permission.camera, Permission.microphone].request();
    final cameraOk = statuses[Permission.camera]?.isGranted ?? false;
    final micOk = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraOk || !micOk) {
      if (mounted) setState(() => _joining = false);
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
      if (mounted) setState(() => _joining = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call konnte nicht gestartet werden.')),
      );
      return;
    }

    if (!context.mounted) return;
    await openVideoCall(context, ref, call);
    _dismissIncomingWindow();
  }
}

class _IncomingCallWindow extends StatelessWidget {
  const _IncomingCallWindow({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.isJoining,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 12;

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Card(
            elevation: 10,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.videocam_outlined),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed: isJoining ? null : onPrimary,
                              child: isJoining
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(primaryLabel),
                            ),
                            TextButton(
                              onPressed: isJoining ? null : onSecondary,
                              child: Text(secondaryLabel),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
