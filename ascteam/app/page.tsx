import { LinkButton } from "./components/ui";

export default function Home() {
  return (
    <section className="flex flex-col gap-4 py-12">
      <h1 className="text-3xl font-bold sm:text-4xl">Ton équipe, organisée.</h1>
      <p className="max-w-xl text-text-muted">
        Calendrier partagé, réponses aux convocations, membres et messages au même endroit.
      </p>
      <div className="flex gap-3">
        <LinkButton href="/calendar">Ouvrir le calendrier</LinkButton>
        <LinkButton href="/members" variant="secondary">Voir les membres</LinkButton>
      </div>
    </section>
  );
}
