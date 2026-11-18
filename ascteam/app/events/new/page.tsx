import { createEventAction } from "../../actions";
import { listTeams } from "@/lib/data";
import { KIND_LABEL } from "@/lib/format";
import { Button, Card, Field, PageTitle, inputClass } from "../../components/ui";

export const metadata = { title: "Nouvel événement" };

const ERRORS: Record<string, string> = {
  missing: "Renseigne au moins le titre, le type, le début et la fin.",
  order: "La fin doit être après le début.",
};

export default async function NewEventPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;
  const teams = await listTeams();

  return (
    <>
      <PageTitle>Nouvel événement</PageTitle>
      <Card className="max-w-xl">
        {error && (
          <p role="alert" className="mb-4 rounded-md border border-danger p-3 text-sm text-danger">
            {ERRORS[error] ?? "Impossible d'enregistrer."}
          </p>
        )}
        <form action={createEventAction} className="flex flex-col gap-4">
          <Field label="Titre" id="title">
            <input id="title" name="title" required className={inputClass} />
          </Field>
          <Field label="Type" id="kind">
            <select id="kind" name="kind" required className={inputClass}>
              {Object.entries(KIND_LABEL).map(([v, l]) => (
                <option key={v} value={v}>{l}</option>
              ))}
            </select>
          </Field>
          <Field label="Équipe" id="teamId" hint="Laisse vide pour un événement de tout le club.">
            <select id="teamId" name="teamId" className={inputClass}>
              <option value="">Tout le club</option>
              {teams.map((t) => (
                <option key={t.id} value={t.id}>{t.name}</option>
              ))}
            </select>
          </Field>
          <Field label="Début" id="startsAt">
            <input id="startsAt" name="startsAt" type="datetime-local" required className={inputClass} />
          </Field>
          <Field label="Fin" id="endsAt">
            <input id="endsAt" name="endsAt" type="datetime-local" required className={inputClass} />
          </Field>
          <Field label="Lieu" id="place">
            <input id="place" name="place" className={inputClass} />
          </Field>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" name="inviteTeam" defaultChecked className="h-4 w-4" />
            Inviter tous les membres de l'équipe
          </label>
          <div>
            <Button type="submit">Créer l'événement</Button>
          </div>
        </form>
      </Card>
    </>
  );
}
