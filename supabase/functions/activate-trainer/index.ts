import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // User-scoped client: anon key + caller's Authorization header.
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Service-role client for privileged DB writes.
    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { code } = await req.json()
    const normalizedCode = (code ?? '').trim().toUpperCase()

    if (!normalizedCode) {
      return new Response(JSON.stringify({ error: 'Code erforderlich.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Look up the invite code.
    const { data: invite, error: lookupError } = await serviceClient
      .from('trainer_invite_codes')
      .select('id, used_by, expires_at')
      .eq('code', normalizedCode)
      .maybeSingle()

    if (lookupError) {
      return new Response(JSON.stringify({ error: lookupError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!invite) {
      return new Response(JSON.stringify({ error: 'Ungültiger Code.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (invite.used_by !== null) {
      return new Response(
        JSON.stringify({ error: 'Dieser Code wurde bereits verwendet.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (new Date(invite.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({ error: 'Dieser Code ist abgelaufen.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Mark code used and promote role in parallel.
    const [{ error: markError }, { error: roleError }] = await Promise.all([
      serviceClient
        .from('trainer_invite_codes')
        .update({ used_by: user.id, used_at: new Date().toISOString() })
        .eq('id', invite.id),
      serviceClient
        .from('profiles')
        .update({ role: 'trainer' })
        .eq('id', user.id),
    ])

    if (markError || roleError) {
      return new Response(
        JSON.stringify({ error: (markError ?? roleError)!.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
