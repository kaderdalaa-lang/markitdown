import Link from "next/link";
import { listEvents, listTeams } from "@/lib/repo";
import { KIND_LABEL, dayKey, formatDay, formatTime } from "@/lib/format";
import { Card, Chip, EmptyState, LinkButton, PageTitle } from "../components/ui";

export const metadata = { title: "Calendrier" };

export default async function CalendarPage({ searchParams }: { searchParams: Promise<{ team?: string }> }) {
  const { team } = await searchParams;
  const [teams, events] = await Promise.all([listTeams(), listEvents({ teamId: team })]);

  const groups = new Map<string, typeof events>();
  for (const e of events) {
    const k = dayKey(e.startsAt);
    groups.set(k, [...(groups.get(k) ?? []), e]);
  }

  return (
    <>
      <PageTitle action={<LinkButton href="/events/new">Nouvel événement</LinkButton>}>Calendrier</PageTitle>

      <div role="group" aria-label="Filtrer par équipe" className="mb-6 flex flex-wrap gap-2">
        <Chip href="/calendar" active={!team}>Toutes</Chip>
        {teams.map((t) => (
          <Chip key={t.id} href={`/calendar?team=${t.id}`} active={team === t.id}>{t.name}</Chip>
        ))}
      </div>

      {events.length === 0 ? (
        <EmptyState text="Aucun événement à venir." action={<LinkButton href="/events/new">Créer un événement</LinkButton>} />
      ) : (
        <div className="flex flex-col gap-6">
          {[...groups.entries()].map(([key, dayEvents]) => (
            <section key={key} aria-labelledby={`day-${key}`}>
              <h2 id={`day-${key}`} className="mb-2 text-sm font-semibold capitalize text-text-muted">
                {formatDay(dayEvents[0].startsAt)}
              </h2>
              <ul className="flex flex-col gap-2">
                {dayEvents.map((e) => (
                  <li key={e.id}>
                    <Link href={`/events/${e.id}`} className="block rounded-lg outline-none">
                      <Card className="flex flex-wrap items-center justify-between gap-2 hover:bg-surface">
                        <div>
                          <p className="font-semibold">{e.title}</p>
                          <p className="text-sm text-text-muted">
                            {formatTime(e.startsAt)} – {formatTime(e.endsAt)} · {e.place || "Lieu à définir"}
                          </p>
                        </div>
                        <span className="rounded-pill border border-border px-3 py-1 text-xs text-text-muted">
                          {KIND_LABEL[e.kind]}
                        </span>
                      </Card>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      )}
    </>
  );
}
