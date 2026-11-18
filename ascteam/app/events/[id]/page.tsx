import { notFound } from "next/navigation";
import { CURRENT_MEMBER_ID, getEvent, getMyAnswer, listAttendance, listTeams } from "@/lib/data";
import { ANSWER_LABEL, KIND_LABEL, formatDay, formatTime } from "@/lib/format";
import { Card, EmptyState, PageTitle } from "../../components/ui";
import { RsvpControl } from "../../components/RsvpControl";

export default async function EventPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const event = await getEvent(id);
  if (!event) notFound();

  const [attendance, myAnswer, teams] = await Promise.all([
    listAttendance(id),
    getMyAnswer(id, CURRENT_MEMBER_ID),
    listTeams(),
  ]);
  const team = teams.find((t) => t.id === event.teamId);
  const locked = new Date(event.startsAt) < new Date();

  return (
    <>
      <PageTitle>{event.title}</PageTitle>
      <div className="grid gap-4 md:grid-cols-2">
        <Card className="flex flex-col gap-3">
          <p className="text-sm text-text-muted">{KIND_LABEL[event.kind]} · {team?.name ?? "Tout le club"}</p>
          <p className="capitalize">{formatDay(event.startsAt)}</p>
          <p>{formatTime(event.startsAt)} – {formatTime(event.endsAt)}</p>
          <p className="text-text-muted">{event.place || "Lieu à définir"}</p>
          <RsvpControl eventId={id} current={myAnswer} locked={locked} />
          {locked && <p className="text-xs text-text-muted">L'événement a commencé, les réponses sont fermées.</p>}
        </Card>

        <Card>
          <h2 className="mb-3 font-semibold">Présences</h2>
          {attendance.length === 0 ? (
            <EmptyState text="Personne n'est invité à cet événement." />
          ) : (
            <ul className="flex flex-col divide-y divide-border">
              {attendance.map((a) => (
                <li key={a.memberId} className="flex items-center justify-between py-2">
                  <span>{a.member.firstName} {a.member.lastName}</span>
                  <span className="text-sm text-text-muted">{ANSWER_LABEL[a.answer]}</span>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>
    </>
  );
}
