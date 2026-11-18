# Recon map: SportEasy (web + mobile)

Scope: team and club admin core loop: schedule events, invite members, track availability and attendance, message the team, collect membership fees.
For: ASCteam, a test clone. Not for shipping.
Date: 2026-11-18
Evidence level: public pages and public help articles only. No account used. No screenshots taken. Screens inside the logged-in app are inferred from help articles and feature pages, marked `guess` where not confirmed.

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | marketing home (fr, redirected) | https://www.sporteasy.net/fr/ | positioning, core loop in their words, ratings |
| 2 | club features (en) | https://www.sporteasy.net/en/clubs/features/amateur-club-software/ | feature list, roles |
| 3 | member management | https://www.sporteasy.net/en/clubs/features/member-management/ | member data model, roles and visibility |
| 4 | payments and fees | https://www.sporteasy.net/en/clubs/features/payments-and-fees/ | fee products, rates, coupons, forms |
| 5 | plans and pricing | https://www.sporteasy.net/en/clubs/plans/ | gated features (checkmarks not in extracted text, see notes) |
| 6 | help: club calendar | https://sporteasy.zendesk.com/hc/en-gb/articles/9036139744412-Keep-track-of-all-club-events | shared calendar, filters, club events |
| 7 | help: messaging | https://sporteasy.zendesk.com/hc/en-gb/articles/9036069099292-Messaging-system | threads, event chat, media |
| 8 | help: team calendar views | https://sporteasy.zendesk.com/hc/en-gb/articles/360023527393-How-to-view-all-the-events-of-your-teams-in-a-CLUB-calendar | filter by event type |
| 9 | pricing page (en) | https://www.sporteasy.net/en/pricing | 404 at time of recon, not used |

Also listed as help-center topics, not read: Invitations and reminders, Easy communication with your members, Managing your member database, Analysing your stats, Prepare my club for the season, Payment collections: pre-orders.

## Core loop

A club or team admin creates an event, members see it and answer yes, no or maybe, and the admin sees who is coming and messages the group about it.

## Roles (from sources 2, 3, 6)

- Club manager: full club admin, all teams, member database, fees, sponsors
- Team coach or educator: manages own team (invitations, reminders, messages, attendance)
- Player: sees team events, answers availability, reads messages
- Parent: same as player for minors, acts on child's profile
- Volunteer or board member: sees club-level groups

## Screens

Public (read):

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Marketing home | / | sign-up CTAs, social proof, role split | hero, role cards, logo wall, testimonials, CTA | default |
| S02 | Club features | /en/clubs/features/... | feature index | feature tiles | default |
| S03 | Member management | /en/clubs/features/member-management/ | member DB marketing | text, screenshots | default |
| S04 | Payments and fees | /en/clubs/features/payments-and-fees/ | fee products marketing | text, screenshots | default |
| S05 | Plans and pricing | /en/clubs/plans/ | tier comparison, monthly/yearly toggle | pricing table, toggle, CTA | default, monthly, yearly |
| S06 | Plans (fr) footer link | /fr/ | language switch | nav | default |

In-app (inferred from help articles, not confirmed in an account):

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S07 | Club calendar | club > calendar tab | all teams' events in one view | day/week/month/season switch, filter by team and type, event card | guess: empty, filled |
| S08 | Event detail | click event | info, attendance, event chat, edit or cancel | details, RSVP list, chat thread | guess: upcoming, past, cancelled |
| S09 | Event create | calendar > create | create training, match, or club event | form: type, team, date, place, invitees | guess: validation error |
| S10 | Team messaging | messaging tab > create | 1-to-1, group, team, event thread | recipient picker, subject, composer, attachments | guess: empty, filled |
| S11 | Member database | club > members | list, filter, sort, export, edit profile | table, filter, profile drawer, file attachments | guess: empty, filled |
| S12 | Fee collections | club > finance | create product, rates, coupons, track payments | product form, rate table, payments list, reminders | guess: empty, paid, overdue |
| S13 | Member registration form | shared link | new member signs up and pays | public form, payment step | guess: step 1 info, step 2 pay, done |
| S14 | Stats | team > stats | team, player and live stats | charts, leaderboard | guess: empty, filled |
| S15 | Votes and ratings | after game | rate game and players | rating widgets | guess |

## Flows

```
F01 Admin creates a training session and invites the team
    S07 club calendar -> S09 event create -> S08 event detail (invites sent)
    happy path clicks: 4 (open calendar, create, pick team and time, save)
    edge: event on a pitch already booked, cancel after invites sent, invitee with two teams

F02 Member answers an invitation
    notification -> S08 event detail -> yes / no / maybe
    happy path clicks: 2
    edge: reminder before the deadline, change answer later, parent answers for a child

F03 Admin messages the team about an event
    S08 event detail -> event chat -> send message or photo
    happy path clicks: 3
    edge: message to a subset of members, attachments (photo, video, PDF)

F04 Admin sends a team-wide message
    S10 messaging -> create -> recipients (team / role / members) -> compose -> send
    happy path clicks: 4

F05 Admin imports and edits members
    S11 member database -> import or add -> fill profile -> attach file
    happy path clicks: unknown (import flow not read)
    edge: duplicate member, missing parent contact, privacy setting per field

F06 Admin creates a fee product and collects payment
    S12 fee collections -> create product (validity, rates, coupon, options, form) -> publish
    member: notification -> pay online via Stripe
    happy path clicks (member): 3
    edge: instalments, VAT, offline payment entered by treasurer, late reminder

F07 New member joins through a registration link
    S13 registration form -> personal info -> pay -> joined
    happy path clicks: unknown
    edge: fee not yet published, minor needs parent details

F08 Parent or player signs up a club
    S01 home -> sign up club (free for 30 days) -> choose plan
    happy path clicks: 3
```

Trial: 30-day free trial on club sign-up (source 4, 5).

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| Button | primary, secondary, ghost, danger | default, hover, focus, disabled, loading | all |
| Calendar grid | day, week, month, season | today, event, empty, filtered | S07 |
| Filter chips | team, event type | on, off, count | S07, S10, S11 |
| Event card | training, match, club event, cancelled | upcoming, past, cancelled | S07, S08 |
| RSVP control | yes, no, maybe | unset, selected, deadline passed | S08 |
| Thread list | 1-to-1, group, team, event | unread, read | S10 |
| Composer | text, with attachment | empty, typing, uploading, sent | S10, S08 |
| Recipient picker | single, few, whole team, role | empty, selected | S10 |
| Data table | sortable, filterable, exportable | loading, empty, filled | S11, S12 |
| Profile drawer | view, edit | clean, dirty, saving | S11 |
| Fee product form | single rate, multi rate, coupon, option, form | valid, invalid | S12 |
| Pricing table | tier, monthly/yearly | default, selected tier | S05 |
| Feature tile | with icon, link | default, hover | S02 |

## Inferred data model

```
Club           id, name, sport, address, season, plan_tier, trial_ends_at
               evidence: S05 plans, S01 club sign-up. confidence: high

Team           id, club_id, name, category (age group), sport
               evidence: S07 team filter, F01. confidence: high

Group          id, club_id, name, member_ids
               evidence: features page "team and group management". confidence: high

Member         id, club_id, first_name, last_name, dob, licence_number, roles[]
               roles: manager | coach | player | parent | volunteer
               privacy_flags per field (JSON)
               evidence: S03, S11. confidence: high

Membership     id, member_id, season, status (pending | paid | overdue | cancelled)
               evidence: S04 validity period, S12. confidence: medium

TeamMembership id, team_id, member_id, role_in_team (player | coach)
               evidence: F02 team invites, S14 player stats. confidence: high

Event          id, club_id, team_id nullable (null = club-wide), type (training | match | meeting | party | other),
               title, starts_at, ends_at, place, status (scheduled | cancelled | postponed), created_by
               evidence: S07, S09, help article "Keep track of all club events". confidence: high

Invitation     id, event_id, member_id, answer (yes | no | maybe | none), answered_at, reminder_sent_at
               evidence: F02, feature list "event invitations, automatic reminders, players availability". confidence: high

Thread         id, club_id, kind (direct | group | team | event), subject, event_id nullable
               evidence: S10, "event chat" in source 7. confidence: high

Message        id, thread_id, author_id, body, created_at, deleted_at
               evidence: source 7 "delete a message". confidence: high

Attachment     id, owner_type, owner_id, kind (photo | video | pdf | file), storage_key
               evidence: source 7 share photos, source 3 member files. confidence: high

FeeProduct     id, club_id, name, valid_from, valid_to, kind (membership | equipment | event)
               evidence: S04. confidence: high

FeeRate        id, fee_product_id, label (adult, youth, unemployed), amount_cents
               evidence: S04 "rates by age group". confidence: high

Coupon         id, fee_product_id, code, percent_off or amount_off
               evidence: S04 coupon. confidence: high

Payment        id, membership_id or order_id, amount_cents, method (online_stripe | cheque | cash), status, paid_at
               evidence: S04 online via Stripe, manual offline entry. confidence: high

Sponsor        id, club_id, name, banner_asset, contract_until
               evidence: sponsor pages. confidence: medium

Vote           id, event_id, member_id, score
               evidence: plans table "votes and ratings after each game". confidence: guess

Stat           id, event_id, member_id, metric, value
               evidence: plans table "team and player statistics". confidence: guess
```

Relationships: Club 1-n Team, Club 1-n Member, Member n-n Team (via TeamMembership), Member n-n Group, Team 1-n Event, Event 1-n Invitation, Invitation n-1 Member, Thread 1-n Message, Member 1-n Membership, FeeProduct 1-n FeeRate, FeeProduct 1-n Coupon, Membership 1-n Payment.

## Feature matrix

See `features.csv`. Must: 16, should: 8, could: 6, skip: 1 (31 rows).

## Out of scope (cannot or should not be cloned)

- Stripe as payment rails: use Stripe directly (allowed as an integration), do not copy SportEasy's account or merchant setup
- Sponsor ad network and the 150 000 reviews, member counts, club logos and testimonials: their content, not the product
- Club logos, photos and marketing copy on the home page: not ours
- Live sports data feed and player stat provider: partner data, not public
- Mobile apps: rebuilt as web first, native later if needed
- SportEasy's own club data, members, clubs and accounts: never touched
- Full club-season administration (licensing with federations, insurance): regulated by sport federations, not in this slice

## Size

Screens 15 (6 public read, 9 in-app inferred), flows 8, entities 18. Hard parts: availability and reminders (scheduled jobs), messaging with attachments and access rules per team and role, payments with Stripe including instalments and VAT, per-field privacy on member profiles, role-based visibility across club and team scope. Size: L.

## Open items for next step

- Logged-in app not inspected. Screens S07 to S15 need the user's own club account, with the user present, before the design step can trust them.
- Pricing table check marks did not come through in extracted text, so tier gating per feature is unconfirmed.
- Help articles on invitations, member database and season setup were listed but not read.
