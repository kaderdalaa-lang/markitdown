import { NextResponse, type NextRequest } from "next/server";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Called by pg_net every 5 min. Drains email_outbox through Resend.
// Auth: Bearer JOB_SECRET (set the same value as app.job_secret in Postgres).
export async function POST(request: NextRequest) {
  const secret = process.env.JOB_SECRET;
  if (!secret || request.headers.get("authorization") !== `Bearer ${secret}`) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
  const apiKey = process.env.RESEND_API_KEY;
  const from = process.env.EMAIL_FROM;
  if (!apiKey || !from) return NextResponse.json({ error: "email not configured" }, { status: 503 });

  const db = supabaseAdmin();
  const { data: rows, error } = await db
    .from("email_outbox")
    .select("id, to_email, subject, body, attempts")
    .is("sent_at", null)
    .lt("attempts", 3)
    .order("created_at")
    .limit(50);
  if (error) return NextResponse.json({ error: "read failed" }, { status: 500 });

  let sent = 0;
  let failed = 0;
  for (const row of rows ?? []) {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
      body: JSON.stringify({ from, to: [row.to_email], subject: row.subject, text: row.body }),
    });
    if (res.ok) {
      sent++;
      await db.from("email_outbox").update({ sent_at: new Date().toISOString(), attempts: row.attempts + 1 }).eq("id", row.id);
    } else {
      failed++;
      await db.from("email_outbox").update({ attempts: row.attempts + 1, last_error: `resend ${res.status}` }).eq("id", row.id);
    }
  }
  return NextResponse.json({ sent, failed });
}
