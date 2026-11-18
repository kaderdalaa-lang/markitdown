# Components: ASCteam

Source: `recon.md` component list. Values from `tokens.json`. Screens from recon (S-IDs).
Status: specs written. Primitives not built yet (no app scaffold in the repo; built in replica-build).

## Button

```
Button
  variants  primary (accent), secondary (surface + border), ghost, danger
  sizes     sm 32px, md 40px, lg 48px
  states    default, hover (darken 6%), active, focus-visible (--focus-ring), disabled (50% opacity, no pointer), loading (spinner, label kept, aria-busy)
  tokens    bg accent, text on-accent, radius md, font sm/600, transition fast
  a11y      real <button>, visible focus ring, loading keeps label for screen readers
  used on   S07, S08, S09, S10, S11, S12
```

## Calendar grid

```
CalendarGrid
  variants  day, week, month, season
  states    today (accent ring), event (chip with team colour dot), empty (muted text "No events"), filtered (dimmed non-matching)
  tokens    border border, text-muted for time labels, radius sm for chips
  a11y      cells are buttons with aria-label "Tuesday 14 January, 2 events"; arrow keys move between cells
  used on   S07
```

## Filter chips

```
FilterChip
  variants  team, event type
  states    off (border, text), on (accent border and tint), count badge
  a11y      role="switch" aria-checked
  used on   S07, S10, S11
```

## Event card

```
EventCard
  variants  training, match, meeting, party, other (kind label, not colour alone)
  states    upcoming, past (muted), cancelled (strike title, danger label)
  tokens    bg surface, radius md, shadow card
  a11y      time and kind in text, not only colour
  used on   S07, S08
```

## RSVP control

```
RsvpControl
  variants  yes, no, maybe (segmented control)
  states    unset (none selected), selected, saving, deadline passed (disabled, text explains)
  a11y      radiogroup with labels "Yes, I'm coming"; state announced on change
  used on   S08
```

## Thread list and composer

```
ThreadList
  variants  direct, group, team, event
  states    unread (bold + dot), read, empty
  used on   S10

Composer
  states    empty (placeholder), typing, uploading (progress), sent, error (retry)
  attachments  photo, video, PDF; size shown; max 25 MB
  a11y      Enter sends, Shift+Enter newline, label on file button
  used on   S08, S10
```

## Recipient picker

```
RecipientPicker
  variants  single, a few, whole team, role (coaches, parents)
  states    empty, selected (chips with remove button), no match
  a11y      combobox with listbox, chip remove has label
  used on   S10
```

## Data table

```
DataTable
  variants  sortable, filterable, exportable
  states    loading (skeleton rows), empty (muted message), filled, sorted column (aria-sort)
  tokens    border border, row hover surface
  a11y      real <table>, header scope, sort buttons in headers
  used on   S11, S12 (no payments: only roster and stats), S14
```

## Profile drawer

```
ProfileDrawer
  variants  view, edit
  states    clean, dirty (save enabled), saving, error (inline per field)
  behaviour privacy-hidden fields show "Visible to admins" label
  a11y      focus trapped, Escape closes, returns focus to trigger
  used on   S11
```

## Form field

```
Field
  states    default, focus (ring), invalid (danger text + icon, aria-describedby), disabled, read-only
  tokens    border-input (3:1 minimum, passes), radius sm, font base
  used on   every form: S02 sign-up, S09, S11, roster import
```

## Modal and toast

```
Modal
  states    open, closing (motion base)
  a11y      role="dialog", aria-modal, focus trap, Escape closes
  used on   S09 confirm cancel event, S11 delete member

Toast
  variants  success, danger, neutral
  states    entering, visible (5 s), dismissed
  a11y      role="status" for success, role="alert" for danger
```

## Empty states

```
EmptyState
  parts     one line of text (muted), one primary action
  copy      written fresh per screen (no SportEasy copy)
  used on   S07 no events, S10 no threads, S11 no members (points to import), S14 no stats yet
```

## Pricing table

Dropped. The app is free (decision 2026-11-18). Recon S05 is not built.

## Navigation

```
AppShell
  desktop   left sidebar 240px (Calendar, Teams, Messages, Members, Stats, Settings)
  mobile    bottom tab bar, 4 items + More
  header    48px, club switcher, avatar menu
  a11y      skip link, current item aria-current="page"
```

## Accessibility baseline

- Contrast: every pair in tokens.json passes AA (run `contrast.py`, 0 failing).
- Targets: 40px minimum for touch controls on mobile.
- Motion: respect `prefers-reduced-motion`, disable transitions over 120 ms.
- Focus: visible everywhere, never removed.

## Open items

- Original screenshots not taken, so the layout, measurements and type scale are from the placeholder only. Not measured from SportEasy.
- Icon set to choose: Lucide (MIT) recommended.
- Font: Inter (open) as the default.
