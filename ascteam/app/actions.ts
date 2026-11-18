"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createEvent, currentMemberId, setAnswer } from "@/lib/repo";
import type { Answer, EventKind } from "@/lib/types";

const KINDS: EventKind[] = ["training", "match", "meeting", "party", "other"];
const ANSWERS: Answer[] = ["yes", "no", "maybe"];

export async function createEventAction(formData: FormData) {
  const title = String(formData.get("title") ?? "").trim();
  const kind = String(formData.get("kind") ?? "") as EventKind;
  const teamId = String(formData.get("teamId") ?? "") || null;
  const startsAt = String(formData.get("startsAt") ?? "");
  const endsAt = String(formData.get("endsAt") ?? "");
  const place = String(formData.get("place") ?? "").trim();

  if (!title || !KINDS.includes(kind) || !startsAt || !endsAt) {
    redirect("/events/new?error=missing");
  }
  if (new Date(endsAt) <= new Date(startsAt)) {
    redirect("/events/new?error=order");
  }

  const event = await createEvent({
    teamId,
    kind,
    title,
    startsAt: new Date(startsAt).toISOString(),
    endsAt: new Date(endsAt).toISOString(),
    place,
    inviteTeam: formData.get("inviteTeam") === "on",
  });
  revalidatePath("/calendar");
  redirect(`/events/${event.id}`);
}

export async function answerAction(formData: FormData) {
  const eventId = String(formData.get("eventId"));
  const answer = String(formData.get("answer")) as Answer;
  if (!ANSWERS.includes(answer)) return;
  const me = await currentMemberId();
  if (!me) redirect("/login");
  await setAnswer(eventId, me, answer);
  revalidatePath(`/events/${eventId}`);
  revalidatePath("/calendar");
}
