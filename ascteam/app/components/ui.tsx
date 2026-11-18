import Link from "next/link";
import type { ReactNode } from "react";

type Variant = "primary" | "secondary" | "ghost" | "danger";

const VARIANT: Record<Variant, string> = {
  primary: "bg-accent text-on-accent hover:brightness-95",
  secondary: "bg-surface text-text border border-border hover:brightness-95",
  ghost: "text-text hover:bg-surface",
  danger: "bg-danger text-on-accent hover:brightness-95",
};

export function buttonClass(variant: Variant = "primary", size: "sm" | "md" = "md") {
  const sz = size === "sm" ? "h-8 px-3 text-sm" : "h-10 px-4 text-sm";
  return `inline-flex items-center justify-center gap-2 rounded-md font-semibold transition duration-fast disabled:opacity-50 disabled:pointer-events-none ${VARIANT[variant]} ${sz}`;
}

export function Button({ variant, size, children, ...rest }: { variant?: Variant; size?: "sm" | "md" } & React.ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button className={buttonClass(variant, size)} {...rest}>
      {children}
    </button>
  );
}

export function LinkButton({ href, variant, size, children }: { href: string; variant?: Variant; size?: "sm" | "md"; children: ReactNode }) {
  return (
    <Link href={href} className={buttonClass(variant, size)}>
      {children}
    </Link>
  );
}

export function Chip({ href, active, children }: { href: string; active: boolean; children: ReactNode }) {
  return (
    <Link
      href={href}
      aria-current={active ? "true" : undefined}
      className={`inline-flex h-8 items-center rounded-pill border px-3 text-sm transition duration-fast ${active ? "border-accent text-accent bg-surface" : "border-border text-text-muted hover:text-text"}`}
    >
      {children}
    </Link>
  );
}

export function Card({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`rounded-lg border border-border bg-bg p-4 shadow-card ${className}`}>{children}</div>;
}

export function EmptyState({ text, action }: { text: string; action?: ReactNode }) {
  return (
    <div className="rounded-lg border border-dashed border-border p-8 text-center">
      <p className="text-text-muted">{text}</p>
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

export function PageTitle({ children, action }: { children: ReactNode; action?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
      <h1 className="text-xl font-bold sm:text-2xl">{children}</h1>
      {action}
    </div>
  );
}

export function Field({ label, id, children, hint }: { label: string; id: string; children: ReactNode; hint?: string }) {
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={id} className="text-sm font-semibold">
        {label}
      </label>
      {children}
      {hint && <p className="text-xs text-text-muted">{hint}</p>}
    </div>
  );
}

export const inputClass =
  "h-10 rounded-md border border-border-input bg-bg px-3 text-text placeholder:text-text-muted w-full";
