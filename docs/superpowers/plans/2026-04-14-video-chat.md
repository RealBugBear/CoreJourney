# Video Chat (Agora) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 1:1 and group video calls to CoreJourney — only Trainers can start calls, Practitioners can only join.

**Architecture:** Agora handles WebRTC media and signalling. A Supabase Edge Function (`agora-token`) generates signed Agora tokens server-side so the App Certificate never leaves the backend. Call metadata (`video_calls` table) is stored in Supabase/PostgreSQL and watched via Supabase Realtime — when a Trainer starts a call the Practitioner sees an incoming call overlay in the chat screen. RLS ensures only channel members can see or create call rows.

**Tech Stack:**
- `agora_rtc_engine: ^6.3.2` — WebRTC video/audio via Agora SDK
- `supabase_flutter` (already present) — `video_calls` Realtime subscription + Edge Function invocation
- `flutter_riverpod` (already present) — providers for call state
- Deno + `agora-access-token@2.0.4` via esm.sh — server-side token generation

---

> ⚠️ **DEV environment only.** All SQL runs against the DEV Supabase project. Never run against production. Check `CLAUDE.md` before any Supabase operation.

> ⚠️ **Agora dev mode:** When `AGORA_APP_CERTIFICATE` is not set (local dev), the Edge Function returns an empty token `""`. This works as long as certificate enforcement is **disabled** on your Agora project (default for new projects). Enable certificate enforcement and set the secret only for production.

> ⚠️ **Incoming call scope:** In this plan, incoming call detection works when the Practitioner has the ChatChannelScreen open. App-wide detection (when the app is in background) requires FCM — deferred until Firebase packages are re-enabled.

---

## File Map

### New files

| Path | Responsibility |
|---|---|
| `supabase/migrations/20260414_video_calls.sql` | `video_calls` table + RLS + index |
| `supabase/functions/agora-token/index.ts` | Deno Edge Function — verifies membership, returns Agora token |
| `lib/features/video/domain/models/video_call.dart` | `VideoCall` immutable value object |
| `lib/features/video/domain/repositories/video_repository.dart` | Abstract `VideoRepository` interface |
| `lib/features/video/data/repositories/supabase_video_repository.dart` | Supabase implementation |
| `lib/features/video/presentation/providers/video_providers.dart` | Riverpod providers for call state |
| `lib/features/video/presentation/screens/video_call_screen.dart` | Full-screen call UI (Agora video) |
| `test/features/video/domain/video_call_test.dart` | Unit tests for VideoCall model |

### Modified files

| Path | Change |
|---|---|
| `pubspec.yaml` | Add `agora_rtc_engine: ^6.3.2` |
| `lib/config/app_config.dart` | Add `agoraAppId` field |
| `lib/bootstrap/bootstrap.dart` | Read `AGORA_APP_ID` from dotenv |
| `ios/Runner/Info.plist` | Add camera + microphone usage descriptions |
| `lib/features/chat/presentation/screens/chat_channel_screen.dart` | Replace Phase-2 snackbar with real call start; add incoming call listener |

---

## Task 1: Supabase SQL Migration — video_calls

**Files:**
- Create: `supabase/migrations/20260414_video_calls.sql`

- [ ] **Step 1.1 — Write migration file**

```sql
-- supabase/migrations/20260414_video_calls.sql
-- Run in DEV Supabase SQL editor. Idempotent: safe to re-run.

-- ── 1. video_calls ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS video_calls (
    id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id         uuid        NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
    agora_channel_name text        NOT NULL UNIQUE,
    started_by         uuid        NOT NULL REFERENCES profiles(id),
    started_at         timestamptz NOT NULL DEFAULT now(),
    ended_at           timestamptz           -- null = call still active
);

-- ── 2. Index ──────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_video_calls_channel
    ON video_calls(channel_id, started_at DESC);

-- ── 3. RLS ───────────────────────────────────────────────────

ALTER TABLE video_calls ENABLE ROW LEVEL SECURITY;

-- SELECT: user must be a member of the chat channel
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'video_calls' AND policyname = 'video_calls_select_member'
  ) THEN
    CREATE POLICY video_calls_select_member ON video_calls
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM chat_channel_members
          WHERE chat_channel_members.channel_id = video_calls.channel_id
            AND chat_channel_members.user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- INSERT: only moderators (trainers) can create calls
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'video_calls' AND policyname = 'video_calls_insert_moderator'
  ) THEN
    CREATE POLICY video_calls_insert_moderator ON video_calls
      FOR INSERT
      WITH CHECK (
        started_by = auth.uid()
        AND EXISTS (
          SELECT 1 FROM chat_channel_members
          WHERE chat_channel_members.channel_id = video_calls.channel_id
            AND chat_channel_members.user_id = auth.uid()
            AND chat_channel_members.role = 'moderator'
        )
      );
  END IF;
END $$;

-- UPDATE: only the person who started the call can end it (set ended_at)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'video_calls' AND policyname = 'video_calls_update_started_by'
  ) THEN
    CREATE POLICY video_calls_update_started_by ON video_calls
      FOR UPDATE
      USING (started_by = auth.uid());
  END IF;
END $$;
```

- [ ] **Step 1.2 — Apply migration in DEV Supabase SQL editor**

Paste the content of `supabase/migrations/20260414_video_calls.sql` into the Supabase DEV SQL editor and run it.

Expected: "Success. No rows returned."

- [ ] **Step 1.3 — Commit**

```bash
git add supabase/migrations/20260414_video_calls.sql
git commit -m "feat(video): video_calls table + RLS migration (DEV)"
```

---

## Task 2: VideoCall Domain Model + VideoRepository Interface + Tests

**Files:**
- Create: `lib/features/video/domain/models/video_call.dart`
- Create: `lib/features/video/domain/repositories/video_repository.dart`
- Create: `test/features/video/domain/video_call_test.dart`

- [ ] **Step 2.1 — Write the failing test first**

```dart
// test/features/video/domain/video_call_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/video/domain/models/video_call.dart';

void main() {
  const activeJson = <String, dynamic>{
    'id': 'call-1',
    'channel_id': 'channel-1',
    'agora_channel_name': 'cj_abc12345_1712345678000',
    'started_by': 'user-trainer',
    'started_at': '2026-04-14T10:00:00.000Z',
    'ended_at': null,
  };

  final endedJson = <String, dynamic>{
    ...activeJson,
    'ended_at': '2026-04-14T10:30:00.000Z',
  };

  group('VideoCall — fromJson', () {
    test('parses all fields correctly', () {
      final call = VideoCall.fromJson(activeJson);
      expect(call.id, 'call-1');
      expect(call.channelId, 'channel-1');
      expect(call.agoraChannelName, 'cj_abc12345_1712345678000');
      expect(call.startedBy, 'user-trainer');
      expect(call.endedAt, isNull);
    });

    test('parses ended_at when set', () {
      final call = VideoCall.fromJson(endedJson);
      expect(call.endedAt, isNotNull);
    });
  });

  group('VideoCall — isActive', () {
    test('true when endedAt is null', () {
      final call = VideoCall.fromJson(activeJson);
      expect(call.isActive, isTrue);
    });

    test('false when endedAt is set', () {
      final call = VideoCall.fromJson(endedJson);
      expect(call.isActive, isFalse);
    });
  });

  group('VideoCall — Equatable', () {
    test('equal when same fields', () {
      final a = VideoCall.fromJson(activeJson);
      final b = VideoCall.fromJson(activeJson);
      expect(a, equals(b));
    });

    test('unequal when endedAt differs', () {
      final a = VideoCall.fromJson(activeJson);
      final b = VideoCall.fromJson(endedJson);
      expect(a, isNot(equals(b)));
    });
  });
}
```

- [ ] **Step 2.2 — Run test to confirm it fails**

```bash
flutter test test/features/video/domain/video_call_test.dart -v
```

Expected: FAIL with `Error: uri 'package:corejourney/features/video/domain/models/video_call.dart' is not an import.`

- [ ] **Step 2.3 — Write VideoCall model**

```dart
// lib/features/video/domain/models/video_call.dart

import 'package:equatable/equatable.dart';

class VideoCall extends Equatable {
  const VideoCall({
    required this.id,
    required this.channelId,
    required this.agoraChannelName,
    required this.startedBy,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String channelId;
  final String agoraChannelName;
  final String startedBy;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isActive => endedAt == null;

  factory VideoCall.fromJson(Map<String, dynamic> json) => VideoCall(
        id: json['id'] as String,
        channelId: json['channel_id'] as String,
        agoraChannelName: json['agora_channel_name'] as String,
        startedBy: json['started_by'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] == null
            ? null
            : DateTime.parse(json['ended_at'] as String),
      );

  @override
  List<Object?> get props =>
      [id, channelId, agoraChannelName, startedBy, startedAt, endedAt];
}
```

- [ ] **Step 2.4 — Write VideoRepository interface**

```dart
// lib/features/video/domain/repositories/video_repository.dart

import '../models/video_call.dart';

abstract class VideoRepository {
  /// Trainer inserts a new video_calls row and returns the created call.
  Future<VideoCall> startCall(String channelId);

  /// Sets ended_at on the given call (caller = trainer who started it).
  Future<void> endCall(String callId);

  /// Fetches a signed Agora token from the Edge Function.
  /// Returns empty string in dev mode (when certificate enforcement is off).
  Future<String> getAgoraToken(String channelId, String agoraChannelName);

  /// Streams the active call (ended_at IS NULL) for a given channel.
  /// Emits null when no active call exists or the call is ended.
  Stream<VideoCall?> watchActiveCall(String channelId);
}
```

- [ ] **Step 2.5 — Run tests to confirm they pass**

```bash
flutter test test/features/video/domain/video_call_test.dart -v
```

Expected: `All tests passed!` (8 tests)

- [ ] **Step 2.6 — Commit**

```bash
git add lib/features/video/domain/ test/features/video/domain/video_call_test.dart
git commit -m "feat(video): VideoCall model + VideoRepository interface + tests"
```

---

## Task 3: SupabaseVideoRepository

**Files:**
- Create: `lib/features/video/data/repositories/supabase_video_repository.dart`

- [ ] **Step 3.1 — Write SupabaseVideoRepository**

```dart
// lib/features/video/data/repositories/supabase_video_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/video_call.dart';
import '../../domain/repositories/video_repository.dart';

class SupabaseVideoRepository implements VideoRepository {
  final _client = Supabase.instance.client;

  @override
  Future<VideoCall> startCall(String channelId) async {
    final now = DateTime.now();
    // Build a short Agora channel name: prefix + first 8 chars of channel UUID + timestamp.
    // Must be ≤ 64 chars and contain only alphanumeric + underscore.
    final shortId = channelId.replaceAll('-', '').substring(0, 8);
    final agoraChannelName = 'cj_${shortId}_${now.millisecondsSinceEpoch}';
    final userId = _client.auth.currentUser!.id;

    final data = await _client.from('video_calls').insert({
      'channel_id': channelId,
      'agora_channel_name': agoraChannelName,
      'started_by': userId,
    }).select().single();

    return VideoCall.fromJson(data);
  }

  @override
  Future<void> endCall(String callId) async {
    await _client
        .from('video_calls')
        .update({'ended_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', callId);
  }

  @override
  Future<String> getAgoraToken(
    String channelId,
    String agoraChannelName,
  ) async {
    try {
      final response = await _client.functions.invoke(
        'agora-token',
        body: {
          'channel_id': channelId,
          'agora_channel_name': agoraChannelName,
        },
      );
      final token =
          (response.data as Map<String, dynamic>)['token'] as String? ?? '';
      return token;
    } catch (e) {
      // Dev fallback: return empty string when Edge Function is not deployed yet.
      // Works when Agora project has certificate enforcement disabled.
      debugPrint('getAgoraToken error (using empty token): $e');
      return '';
    }
  }

  @override
  Stream<VideoCall?> watchActiveCall(String channelId) {
    return _client
        .from('video_calls')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('started_at', ascending: false)
        .limit(10)
        .map((rows) {
          // Find the most recent row with ended_at = null.
          for (final row in rows) {
            if (row['ended_at'] == null) {
              return VideoCall.fromJson(row);
            }
          }
          return null;
        });
  }
}
```

- [ ] **Step 3.2 — Analyze**

```bash
flutter analyze lib/features/video/
```

Expected: No issues found.

- [ ] **Step 3.3 — Commit**

```bash
git add lib/features/video/data/
git commit -m "feat(video): SupabaseVideoRepository — startCall, endCall, getAgoraToken, watchActiveCall"
```

---

## Task 4: agora-token Edge Function

**Files:**
- Create: `supabase/functions/agora-token/index.ts`

- [ ] **Step 4.1 — Create function directory and write Edge Function**

```typescript
// supabase/functions/agora-token/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const AGORA_APP_ID = Deno.env.get('AGORA_APP_ID')!;
const AGORA_APP_CERTIFICATE = Deno.env.get('AGORA_APP_CERTIFICATE') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

interface RequestPayload {
  channel_id: string;
  agora_channel_name: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const payload: RequestPayload = await req.json();
    const { channel_id, agora_channel_name } = payload;

    if (!channel_id || !agora_channel_name) {
      return new Response(
        JSON.stringify({ error: 'Missing channel_id or agora_channel_name' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Verify caller identity via their JWT.
    const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await serviceClient.auth.getUser(jwt);
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Verify user is a member of this channel.
    const { data: membership } = await serviceClient
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', channel_id)
      .eq('user_id', user.id)
      .single();

    if (!membership) {
      return new Response(JSON.stringify({ error: 'Not a channel member' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Dev mode: no certificate set → return empty token.
    // Agora projects with certificate enforcement disabled accept empty tokens.
    if (!AGORA_APP_CERTIFICATE) {
      console.log('agora-token: no certificate set, returning empty token (dev mode)');
      return new Response(JSON.stringify({ token: '' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Production: generate a signed AccessToken1 via agora-access-token npm package.
    const { RtcTokenBuilder, RtcRole } = await import(
      'https://esm.sh/agora-access-token@2.0.4'
    );
    const expireTs = Math.floor(Date.now() / 1000) + 86_400; // 24 hours
    const token: string = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      agora_channel_name,
      0,              // uid 0 = accept any numeric uid
      RtcRole.PUBLISHER,
      expireTs,
      expireTs,
    );

    return new Response(JSON.stringify({ token }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('agora-token error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
```

- [ ] **Step 4.2 — Deploy Edge Function**

In Supabase dashboard → Edge Functions → Create new function → name: `agora-token` → paste the TypeScript content.

Set Edge Function secrets (Dashboard → Edge Functions → Secrets):
```
AGORA_APP_ID=<your Agora App ID from console.agora.io>
```

Leave `AGORA_APP_CERTIFICATE` unset for dev (empty token mode). Set it only when you want proper signed tokens.

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically by Supabase.

- [ ] **Step 4.3 — Commit**

```bash
git add supabase/functions/agora-token/index.ts
git commit -m "feat(video): agora-token Edge Function — membership check + signed token"
```

---

## Task 5: Package, Config, iOS Permissions

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/config/app_config.dart`
- Modify: `lib/bootstrap/bootstrap.dart`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 5.1 — Add agora_rtc_engine to pubspec.yaml**

In `pubspec.yaml`, add after the `video_player` line:

```yaml
  # Video calls — Agora WebRTC
  agora_rtc_engine: ^6.3.2
```

The `dependencies` block should look like:
```yaml
  # Video
  video_player: ^2.9.1
  flutter_cache_manager: ^3.4.1
  # Video calls — Agora WebRTC
  agora_rtc_engine: ^6.3.2
```

- [ ] **Step 5.2 — Run pub get**

```bash
flutter pub get
```

Expected: Resolves packages without error. No output about incompatibilities.

- [ ] **Step 5.3 — Add agoraAppId to AppConfig**

Full replacement of `lib/config/app_config.dart`:

```dart
// lib/config/app_config.dart

enum AppEnvironment { development, production }

class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatApiKey;
  final String adminEmail;
  final String trainerCode;
  final String agoraAppId;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatApiKey,
    this.adminEmail = '',
    this.trainerCode = '',
    this.agoraAppId = '',
  });

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;

  String get envLabel => isDevelopment ? 'DEV' : 'PROD';
}
```

- [ ] **Step 5.4 — Read AGORA_APP_ID in bootstrap**

In `lib/bootstrap/bootstrap.dart`, find the `AppConfig(...)` constructor call (around line 62) and add `agoraAppId`:

```dart
    final config = AppConfig(
      environment: environment,
      supabaseUrl: dotenv.env['SUPABASE_URL']!,
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      revenueCatApiKey: dotenv.env['REVENUECAT_API_KEY'] ?? '',
      adminEmail: dotenv.env['ADMIN_EMAIL'] ?? '',
      trainerCode: dotenv.env['TRAINER_CODE'] ?? '',
      agoraAppId: dotenv.env['AGORA_APP_ID'] ?? '',
    );
```

- [ ] **Step 5.5 — Add camera + microphone permissions to iOS Info.plist**

In `ios/Runner/Info.plist`, add inside the root `<dict>` (before the closing `</dict>`):

```xml
	<key>NSCameraUsageDescription</key>
	<string>CoreJourney benötigt Kamera-Zugriff für Video-Calls mit deinem Trainer.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>CoreJourney benötigt Mikrofon-Zugriff für Video-Calls mit deinem Trainer.</string>
```

- [ ] **Step 5.6 — Add AGORA_APP_ID to .env.dev**

Open `.env.dev` and add:
```
AGORA_APP_ID=<your Agora App ID from console.agora.io>
```

Do NOT commit `.env.dev` (it is already in `.gitignore`).

- [ ] **Step 5.7 — Analyze**

```bash
flutter analyze lib/
```

Expected: No issues.

- [ ] **Step 5.8 — Commit**

```bash
git add pubspec.yaml pubspec.lock lib/config/app_config.dart lib/bootstrap/bootstrap.dart ios/Runner/Info.plist
git commit -m "feat(video): add agora_rtc_engine, AppConfig.agoraAppId, iOS camera/mic permissions"
```

---

## Task 6: Video Riverpod Providers

**Files:**
- Create: `lib/features/video/presentation/providers/video_providers.dart`

- [ ] **Step 6.1 — Write video_providers.dart**

```dart
// lib/features/video/presentation/providers/video_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_video_repository.dart';
import '../../domain/models/video_call.dart';
import '../../domain/repositories/video_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return SupabaseVideoRepository();
});

// ── Active call stream ────────────────────────────────────────────────────────

/// Streams the currently active VideoCall for a given channelId.
/// Emits null when no call is active or the call has ended.
final activeCallProvider =
    StreamProvider.autoDispose.family<VideoCall?, String>((ref, channelId) {
  return ref.read(videoRepositoryProvider).watchActiveCall(channelId);
});

// ── Start call notifier ───────────────────────────────────────────────────────

class StartCallNotifier extends AutoDisposeAsyncNotifier<VideoCall?> {
  @override
  Future<VideoCall?> build() async => null;

  /// Returns the created VideoCall on success, null on error.
  Future<VideoCall?> start(String channelId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(videoRepositoryProvider).startCall(channelId),
    );
    state = result;
    return result.valueOrNull;
  }
}

final startCallProvider =
    AsyncNotifierProvider.autoDispose<StartCallNotifier, VideoCall?>(
  StartCallNotifier.new,
);

// ── End call notifier ─────────────────────────────────────────────────────────

class EndCallNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> end(String callId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(videoRepositoryProvider).endCall(callId),
    );
  }
}

final endCallProvider =
    AsyncNotifierProvider.autoDispose<EndCallNotifier, void>(
  EndCallNotifier.new,
);
```

- [ ] **Step 6.2 — Analyze**

```bash
flutter analyze lib/features/video/
```

Expected: No issues.

- [ ] **Step 6.3 — Commit**

```bash
git add lib/features/video/presentation/providers/video_providers.dart
git commit -m "feat(video): Riverpod providers — activeCall, startCall, endCall"
```

---

## Task 7: VideoCallScreen

**Files:**
- Create: `lib/features/video/presentation/screens/video_call_screen.dart`

- [ ] **Step 7.1 — Write VideoCallScreen**

```dart
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

    if (mounted) setState(() => _engine = engine);
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
    final iconColor = background != null ? Colors.white : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(icon, color: iconColor, size: 26),
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
```

- [ ] **Step 7.2 — Analyze**

```bash
flutter analyze lib/features/video/
```

Expected: No issues.

- [ ] **Step 7.3 — Commit**

```bash
git add lib/features/video/presentation/screens/video_call_screen.dart
git commit -m "feat(video): VideoCallScreen — Agora video UI, mute, hang up, remote-end detection"
```

---

## Task 8: Wire ChatChannelScreen — Replace Snackbar + Incoming Call Listener

**Files:**
- Modify: `lib/features/chat/presentation/screens/chat_channel_screen.dart`

This task replaces the Phase-2 snackbar with a real `_startCall()` flow and adds an incoming call listener via `ref.listen`.

- [ ] **Step 8.1 — Add video imports to chat_channel_screen.dart**

At the top of `lib/features/chat/presentation/screens/chat_channel_screen.dart`, add these imports after the existing imports:

```dart
import '../../../video/domain/models/video_call.dart';
import '../../../video/presentation/providers/video_providers.dart';
import '../../../video/presentation/screens/video_call_screen.dart';
```

- [ ] **Step 8.2 — Add _startCall() and _showIncomingCall() methods**

In `_ChatChannelScreenState`, add these two methods before the `build()` method:

```dart
  Future<void> _startCall() async {
    final call = await ref.read(startCallProvider.notifier).start(widget.channelId);
    if (call == null) return;
    final token = await ref
        .read(videoRepositoryProvider)
        .getAgoraToken(widget.channelId, call.agoraChannelName);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => VideoCallScreen(call: call, token: token),
      ),
    );
  }

  void _showIncomingCall(VideoCall call) {
    // Guard: only show once; skip if already watching this call.
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Eingehender Video-Call'),
        content: const Text(
          'Dein Trainer möchte mit dir sprechen.\nMöchtest du beitreten?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ignorieren'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final token = await ref
                  .read(videoRepositoryProvider)
                  .getAgoraToken(call.channelId, call.agoraChannelName);
              if (!mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => VideoCallScreen(call: call, token: token),
                ),
              );
            },
            child: const Text('Beitreten'),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 8.3 — Replace snackbar with _startCall() call**

In the `build()` method of `_ChatChannelScreenState`, find the snackbar block (lines ~140-145):

```dart
              onPressed: () {
                // Placeholder until Plan 2 (Video Chat) is implemented.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video-Chat kommt in Phase 2.')),
                );
              },
```

Replace with:

```dart
              onPressed: _startCall,
```

- [ ] **Step 8.4 — Add incoming call listener in build()**

In the `build()` method, add a `ref.listen` call right after `final messagesAsync = ref.watch(chatMessagesProvider(widget.channelId));`:

```dart
    // Listen for active calls started by someone else (incoming call for practitioner).
    ref.listen(activeCallProvider(widget.channelId), (prev, next) {
      final call = next.valueOrNull;
      if (call == null) return;
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
      // Don't show incoming call dialog to the person who started it.
      if (call.startedBy == currentUserId) return;
      // Only show if this is a new call (prev had no active call).
      if (prev?.valueOrNull?.id == call.id) return;
      _showIncomingCall(call);
    });
```

- [ ] **Step 8.5 — Analyze**

```bash
flutter analyze lib/features/chat/presentation/screens/chat_channel_screen.dart
```

Expected: No issues.

- [ ] **Step 8.6 — Commit**

```bash
git add lib/features/chat/presentation/screens/chat_channel_screen.dart
git commit -m "feat(video): wire ChatChannelScreen — start call, incoming call overlay"
```

---

## Task 9: Run Full Test Suite + Final Commit

- [ ] **Step 9.1 — Run all tests**

```bash
flutter test -v
```

Expected: All tests pass. The video domain tests (Task 2) and all existing chat tests should be green.

- [ ] **Step 9.2 — Analyze entire project**

```bash
flutter analyze lib/
```

Expected: No issues.

- [ ] **Step 9.3 — Final commit**

```bash
git add .
git commit -m "feat(video): complete Video Chat Plan 2 — Agora 1:1 calls, incoming overlay"
```

---

## Task 10: Smoke Test Checklist

Manual test steps with the app running on DEV (`make run`).

**Setup:**
1. You need a DEV Supabase channel with a trainer (moderator) and practitioner (member) already inserted (from Plan 1 smoke test).
2. `AGORA_APP_ID` must be set in `.env.dev` and in Supabase Edge Function secrets.
3. Agora project must have certificate enforcement **disabled** (for dev empty-token mode).

| # | Action | Expected |
|---|---|---|
| 1 | Log in as Trainer | Dashboard visible |
| 2 | Open direct channel in Chat | ChatChannelScreen opens, videocam icon in AppBar (top right) |
| 3 | Tap videocam icon | `_startCall()` executes — `video_calls` row inserted, `VideoCallScreen` opens |
| 4 | See VideoCallScreen | Black screen, local PiP (top right), "Warte auf Teilnehmer…" center |
| 5 | Open same channel as Practitioner (second device/simulator) | Incoming call dialog appears: "Eingehender Video-Call" |
| 6 | Practitioner taps "Beitreten" | VideoCallScreen opens on Practitioner side |
| 7 | Both devices show video | Remote video fills screen, local PiP top right |
| 8 | Tap mic button | Mic mutes (icon changes to mic_off) |
| 9 | Tap camera button | Camera mutes (icon changes to videocam_off) |
| 10 | Trainer taps "Auflegen" | `ended_at` set in DB, both screens pop back to ChatChannelScreen |
| 11 | Practitioner taps "Auflegen" first | Same result — `ended_at` set, Trainer screen auto-pops (activeCallProvider emits null) |
| 12 | Practitioner taps "Ignorieren" on incoming call | Dialog dismisses, call remains active, Practitioner stays in chat |

---

## What's Next

After this plan is complete, the remaining video features are:
- **App-wide incoming call overlay** — detect calls when ChatChannelScreen is not open. Requires a global Supabase Realtime listener at the app root level (watches all user channels).
- **Group video calls** — Trainer starts from Community channel; all members receive FCM push. Requires Firebase to be re-enabled.
- **FCM push on call start** — Notify practitioner even when app is backgrounded. Deferred until Firebase packages are re-activated.
