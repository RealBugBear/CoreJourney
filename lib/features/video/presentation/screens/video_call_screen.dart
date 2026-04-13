// lib/features/video/presentation/screens/video_call_screen.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap/providers.dart';
import '../../domain/models/video_call.dart';
import '../providers/video_providers.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.call,
    required this.token,
  });

  final VideoCall call;

  /// Agora token from the Edge Function. Empty string is valid in dev mode
  /// when certificate enforcement is disabled on the Agora project.
  final String token;

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _micMuted = false;
  bool _cameraMuted = false;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    final appId = ref.read(appConfigProvider).agoraAppId;
    if (appId.isEmpty) {
      debugPrint('VideoCallScreen: AGORA_APP_ID is empty — add it to .env.dev');
      return;
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    if (mounted) setState(() => _engine = engine);

    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (mounted) setState(() => _joined = true);
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (mounted) setState(() => _remoteUid = remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (mounted) setState(() => _remoteUid = null);
      },
    ));

    await engine.enableVideo();
    await engine.startPreview();

    await engine.joinChannel(
      token: widget.token,
      channelId: widget.call.agoraChannelName,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Future<void> _hangUp() async {
    if (_ending) return;
    setState(() => _ending = true);
    await ref.read(endCallProvider.notifier).end(widget.call.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // When the remote side ends the call, pop automatically.
    ref.listen(activeCallProvider(widget.call.channelId), (prev, next) {
      if (_joined && next.valueOrNull == null && mounted) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Remote video (full screen background) ──────────────────────────
          if (_engine != null && _remoteUid != null)
            Positioned.fill(
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: _remoteUid!),
                  connection:
                      RtcConnection(channelId: widget.call.agoraChannelName),
                ),
              ),
            )
          else
            const Positioned.fill(
              child: _WaitingState(),
            ),

          // ── Local video (PiP, top-right) ───────────────────────────────────
          if (_engine != null)
            Positioned(
              top: 56,
              right: 16,
              width: 100,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),

          // ── Controls (bottom) ──────────────────────────────────────────────
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: _micMuted ? Icons.mic_off : Icons.mic,
                  label: _micMuted ? 'Ton an' : 'Ton aus',
                  onTap: () {
                    setState(() => _micMuted = !_micMuted);
                    _engine?.muteLocalAudioStream(_micMuted);
                  },
                ),
                const SizedBox(width: 32),
                _ControlButton(
                  icon: Icons.call_end,
                  label: 'Auflegen',
                  background: Colors.red,
                  onTap: _hangUp,
                ),
                const SizedBox(width: 32),
                _ControlButton(
                  icon: _cameraMuted ? Icons.videocam_off : Icons.videocam,
                  label: _cameraMuted ? 'Kamera an' : 'Kamera aus',
                  onTap: () {
                    setState(() => _cameraMuted = !_cameraMuted);
                    _engine?.muteLocalVideoStream(_cameraMuted);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingState extends StatelessWidget {
  const _WaitingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person, size: 80, color: Colors.white38),
        SizedBox(height: 16),
        Text(
          'Warte auf Teilnehmer …',
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? Colors.white.withValues(alpha: 0.2);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
