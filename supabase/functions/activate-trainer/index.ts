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

    // Look up the approval-bound trainer activation code.
    const { data: invite, error: lookupError } = await serviceClient
      .from('trainer_invite_codes')
      .select('id, used_by, expires_at, trainer_application_id, purpose')
      .eq('code', normalizedCode)
      .eq('purpose', 'trainer_application_approval')
      .maybeSingle()

    if (lookupError) {
      return new Response(JSON.stringify({ error: lookupError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!invite) {
      return new Response(JSON.stringify({ error: 'Ungültiger Aktivierungscode.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!invite.trainer_application_id) {
      return new Response(
        JSON.stringify({ error: 'Dieser Code ist nicht mit einer geprüften Bewerbung verbunden.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
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

    const { error: activationError } = await serviceClient.rpc(
      'finalize_trainer_application_activation',
      { p_code: normalizedCode, p_user_id: user.id },
    )

    if (activationError) {
      return new Response(
        JSON.stringify({ error: activationError.message }),
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
