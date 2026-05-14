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
      return json({ error: 'Unauthorized' }, 401)
    }

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) {
      return json({ error: 'Unauthorized' }, 401)
    }

    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: caller, error: callerError } = await serviceClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()
    if (callerError || caller?.role !== 'admin') {
      return json({ error: 'Forbidden' }, 403)
    }

    const body = await req.json() as { user_id?: string; role?: string }
    const userId = body.user_id
    const role = body.role
    if (!userId || !role) {
      return json({ error: 'user_id and role are required' }, 400)
    }
    if (!['practitioner', 'trainer', 'admin'].includes(role)) {
      return json({ error: 'role must be practitioner, trainer, or admin' }, 400)
    }
    if (userId === user.id && role !== 'admin') {
      return json({ error: 'Admins cannot demote their own account' }, 400)
    }

    const { error: updateError } = await serviceClient
      .from('profiles')
      .update({ role })
      .eq('id', userId)
    if (updateError) {
      return json({ error: updateError.message }, 500)
    }

    if (role === 'practitioner') {
      await serviceClient
        .from('trainer_profiles')
        .update({ status: 'suspended', updated_at: new Date().toISOString() })
        .eq('id', userId)
    }

    return json({ success: true, user_id: userId, role })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
