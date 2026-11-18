"use server";

import { redirect } from "next/navigation";
import { headers } from "next/headers";
import { z } from "zod";
import { supabaseServer } from "@/lib/supabase/server";

const Credentials = z.object({
  email: z.string().trim().email().max(254),
  password: z.string().min(8).max(72),
});

export async function signInAction(formData: FormData) {
  const parsed = Credentials.safeParse({ email: formData.get("email"), password: formData.get("password") });
  if (!parsed.success) redirect("/login?error=invalid");
  const supabase = await supabaseServer();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);
  if (error) redirect("/login?error=credentials");
  const next = String(formData.get("next") ?? "/calendar");
  redirect(next.startsWith("/") && !next.startsWith("//") ? next : "/calendar");
}

export async function signUpAction(formData: FormData) {
  const parsed = Credentials.safeParse({ email: formData.get("email"), password: formData.get("password") });
  if (!parsed.success) redirect("/login?mode=signup&error=invalid");
  const origin = (await headers()).get("origin") ?? process.env.NEXT_PUBLIC_SITE_URL ?? "";
  const supabase = await supabaseServer();
  const { error } = await supabase.auth.signUp({
    ...parsed.data,
    options: { emailRedirectTo: `${origin}/auth/callback` },
  });
  if (error) redirect("/login?mode=signup&error=signup");
  redirect("/login?mode=signup&sent=1");
}

