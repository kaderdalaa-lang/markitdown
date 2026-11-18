import Link from "next/link";
import type { ReactNode } from "react";

const NAV = [
  { href: "/calendar", label: "Calendrier" },
  { href: "/members", label: "Membres" },
];

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-bg text-text">
      <a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:left-2 focus:top-2 focus:z-50 focus:rounded-md focus:bg-accent focus:px-3 focus:py-2 focus:text-on-accent">
        Aller au contenu
      </a>
      <header className="sticky top-0 z-10 border-b border-border bg-bg">
        <div className="mx-auto flex h-12 max-w-6xl items-center justify-between px-4">
          <Link href="/" className="font-bold">ASCteam</Link>
          <nav aria-label="Principal" className="flex gap-1">
            {NAV.map((n) => (
              <Link key={n.href} href={n.href} className="rounded-md px-3 py-1.5 text-sm text-text-muted hover:bg-surface hover:text-text">
                {n.label}
              </Link>
            ))}
          </nav>
        </div>
      </header>
      <main id="main" className="mx-auto max-w-6xl px-4 py-6">{children}</main>
    </div>
  );
}
