import { signInAction, signUpAction } from "./actions";
import { Button, Card, Field, PageTitle, inputClass } from "../components/ui";

export const metadata = { title: "Connexion" };

const ERRORS: Record<string, string> = {
  invalid: "Vérifie l'adresse e-mail (8 caractères minimum pour le mot de passe).",
  credentials: "Adresse ou mot de passe incorrect.",
  signup: "Impossible de créer le compte. Essaie une autre adresse.",
  link: "Le lien a expiré ou est invalide. Redemande-le.",
};

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ next?: string; mode?: string; error?: string; sent?: string }> }) {
  const { next = "/calendar", mode, error, sent } = await searchParams;
  const signup = mode === "signup";

  return (
    <>
      <PageTitle>{signup ? "Créer un compte" : "Connexion"}</PageTitle>
      <Card className="max-w-md">
        {sent && <p role="status" className="mb-4 rounded-md border border-success p-3 text-sm">Vérifie ta boîte mail pour confirmer le compte.</p>}
        {error && <p role="alert" className="mb-4 rounded-md border border-danger p-3 text-sm text-danger">{ERRORS[error] ?? "Une erreur est survenue."}</p>}
        <form action={signup ? signUpAction : signInAction} className="flex flex-col gap-4">
          <input type="hidden" name="next" value={next} />
          <Field label="Adresse e-mail" id="email">
            <input id="email" name="email" type="email" autoComplete="email" required className={inputClass} />
          </Field>
          <Field label="Mot de passe" id="password" hint={signup ? "8 caractères minimum." : undefined}>
            <input id="password" name="password" type="password" autoComplete={signup ? "new-password" : "current-password"} minLength={8} required className={inputClass} />
          </Field>
          <Button type="submit">{signup ? "Créer le compte" : "Se connecter"}</Button>
        </form>
        <p className="mt-4 text-sm text-text-muted">
          {signup ? (
            <a className="underline" href="/login">J'ai déjà un compte</a>
          ) : (
            <a className="underline" href="/login?mode=signup">Créer un compte</a>
          )}
        </p>
      </Card>
    </>
  );
}
