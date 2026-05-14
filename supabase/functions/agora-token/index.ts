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
  uid?: number;
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
    const uid = Number.isInteger(payload.uid) && payload.uid! > 0
      ? payload.uid!
      : 1;

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
      uid,
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
