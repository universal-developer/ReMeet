// supabase/functions/mirror_friendship/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { user_id, friend_id } = await req.json();

  if (!user_id || !friend_id || user_id === friend_id) {
    return new Response(JSON.stringify({ error: "Invalid input" }), { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Check if mirror row already exists
  const { data, error: checkError } = await supabase
    .from("friends")
    .select("user_id")
    .eq("user_id", friend_id)
    .eq("friend_id", user_id)
    .maybeSingle();

  if (checkError) {
    return new Response(JSON.stringify({ error: "Check failed" }), { status: 500 });
  }

  if (data) {
    return new Response(JSON.stringify({ message: "Already exists" }), { status: 200 });
  }

  // Insert the mirror friendship
  const { error: insertError } = await supabase.from("friends").insert([
    { user_id: friend_id, friend_id: user_id }
  ]);

  if (insertError) {
    return new Response(JSON.stringify({ error: insertError.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ success: true }), { status: 200 });
});
