import { answerAction } from "../actions";
import { ANSWER_LABEL } from "@/lib/format";
import type { Answer } from "@/lib/types";

const OPTIONS: Answer[] = ["yes", "maybe", "no"];

export function RsvpControl({ eventId, current, locked }: { eventId: string; current: Answer; locked: boolean }) {
  return (
    <fieldset className="flex flex-col gap-2">
      <legend className="text-sm font-semibold">Ta réponse</legend>
      <div className="flex flex-wrap gap-2">
        {OPTIONS.map((opt) => (
          <form key={opt} action={answerAction}>
            <input type="hidden" name="eventId" value={eventId} />
            <input type="hidden" name="answer" value={opt} />
            <button
              type="submit"
              disabled={locked}
              aria-pressed={current === opt}
              className={`h-10 rounded-pill border px-4 text-sm font-semibold transition duration-fast disabled:opacity-50 ${current === opt ? "border-accent bg-accent text-on-accent" : "border-border bg-bg text-text hover:bg-surface"}`}
            >
              {ANSWER_LABEL[opt]}
            </button>
          </form>
        ))}
      </div>
    </fieldset>
  );
}
