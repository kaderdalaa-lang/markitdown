import { listMembers, listTeams } from "@/lib/data";
import { Card, EmptyState, Field, PageTitle, inputClass, Button } from "../components/ui";

export const metadata = { title: "Membres" };

const ROLE: Record<string, string> = { player: "Joueur", coach: "Coach", parent: "Parent", manager: "Dirigeant", volunteer: "Bénévole" };

export default async function MembersPage({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const { q = "" } = await searchParams;
  const [members, teams] = await Promise.all([listMembers(q), listTeams()]);
  const teamName = (id: string) => teams.find((t) => t.id === id)?.name ?? "";

  return (
    <>
      <PageTitle>Membres</PageTitle>
      <form role="search" className="mb-4 flex max-w-md items-end gap-2">
        <Field label="Rechercher" id="q">
          <input id="q" name="q" defaultValue={q} className={inputClass} />
        </Field>
        <Button type="submit" variant="secondary">Chercher</Button>
      </form>

      {members.length === 0 ? (
        <EmptyState text="Aucun membre trouvé." />
      ) : (
        <Card className="overflow-x-auto p-0">
          <table className="w-full text-left text-sm">
            <caption className="sr-only">Liste des membres</caption>
            <thead className="border-b border-border text-text-muted">
              <tr>
                <th scope="col" className="px-4 py-2 font-semibold">Nom</th>
                <th scope="col" className="px-4 py-2 font-semibold">Rôles</th>
                <th scope="col" className="px-4 py-2 font-semibold">Équipes</th>
              </tr>
            </thead>
            <tbody>
              {members.map((m) => (
                <tr key={m.id} className="border-b border-border last:border-0">
                  <th scope="row" className="px-4 py-2 font-medium">{m.firstName} {m.lastName}</th>
                  <td className="px-4 py-2 text-text-muted">{m.roles.map((r) => ROLE[r]).join(", ")}</td>
                  <td className="px-4 py-2 text-text-muted">{m.teamIds.map(teamName).join(", ")}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}
    </>
  );
}
