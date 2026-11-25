# Inventory: what Webwork needs from the first version — Phase 1, question round 5

Input for `../project_idea.ai_runtime.md` (called "the Project Idea" below) for the product
owner's instruction (a) of this round: Webwork's "current state of todos, done and planned" as
part of the feature baseline of the first version, and above all "what it needs for the team
review features and sending review document bundle within the team/users on the TAC".

## 1 What was read, and the date of the state

**State: 2026-11-25** (the webwork todo file was last written at 18:09 that day; the decisions
document `webwork_office_and_review.webwork.md` and `webwork_component_placement.webwork.md`
carry answers of the same morning). The previous round's findings
(`../01_04_Questions Round/inputs_webwork_tom_forge.md`, WW-1 … WW-22, as of 2026-11-20) were
read first; they are not repeated. Where this inventory says "WW-<n> still holds" the finding
stands unchanged; where the Project Idea took a WW finding in round 4 (CV.5, CV.12, CV.13, CV.15,
CU.7, CU.16, CP.13, CP.36, PQ-49, PQ-51, PQ-52) it is not listed again.

**Read:**

- **`_ai/quests/webwork/todos.webwork.todo.yaml`**, listed with Python: 195 entries — 169
  not-started, 21 blocked, 2 in-progress, 1 completed (not yet archived: `audiovideo1`),
  1 decision-needed (`qr48`), 1 group (`caf_17`). Read in full: `09_woneb1` … `09_woneb5`,
  `03a_woneb1`, `03a_woneb13`, `03a_woneb16`, `03a_woneb17`, `12a_woneb1` … `12a_woneb3`,
  `13_woneb1` … `13_woneb10`, `14_woneb2`, `06_woneb6`, `06_woneb9`, `05a_woneb9`,
  `qavs_collab_b-1`, `caf_17a`, `qr48`. The rest by title.
- **`todos-archived.webwork.todo.yaml`**: 794 completed; the 32 completed or archived since
  2026-11-15 listed (the idea deepening `ideadeep1x1-*`, the feasibility probes `02a_woneb4` …
  `02a_woneb6`, `tom_todo_model` 4.0.0 `02a_woneb1` … `02a_woneb3`, `wwremind1`, `officefit1`,
  `d33webview*`, `mdprobe*`); none adds a review or messaging requirement beyond the documents
  below.
- **Decisions of 2026-11-25:** `webwork_office_and_review.webwork.md` (OR-1 … OR-22,
  FQ-1 … FQ-12, Revisions 1 … 4, Part C *The Review area*, Part D);
  `webwork_component_placement.webwork.md` (§ 2.3 C15 … C23, Q-7, Q-8, Q-10);
  `webwork_wave1_plan.md` (regenerated 2026-11-25, "on hold until the re-plan");
  `webwork_on_forge_kit.webwork.md` (FK-9, FK-16, by search).
- **The idea** `ideas/webwork_redesign/webwork_redesign.docspecs.md` (2026-11-25):
  part-review and part-messaging in full.
- **Other quests, only where they define what travels:** vscode_extension `04c_woneb1` …
  `04c_woneb4`; tom_forge `03b_woneb1`, `03b_woneb2`, `05b_woneb5`; tom_specs `05c_woneb1`;
  ai_runtime `webwork_requirements.md` WR-4 … WR-6; the status of the ai_runtime todos Webwork's
  `blocked_by` names.
- **The extension's team review as built:** `tom_ai/vscode/tom_vscode_extension/src/utils/reviewRound.ts`
  (the round folder and `round.yaml`), `src/services/review-team.ts` (members),
  `doc/user_guide.md` (*Team review rounds*, *Consolidating a team review*).
- **The Project Idea** as round 4 left it: `TAC-KINDS` … `TAC-WEBWORK`, `CLI-UI` (CU.1, CU.3,
  CU.6, CU.9, CU.16), CP.13, CP.36, CR.5, O-7, O-10, D-29, D-32, D-54, and the open questions
  PQ-37, PQ-41, PQ-43, PQ-44, PQ-49, PQ-51, PQ-52, PQ-56, PQ-57.

**Not written yet** (cited by the todos that will write them): D39 `wave1b.spec_review`
(`03a_woneb16`, `03a_woneb17`), D40 `wave1b.spec_messaging` (`12a_woneb2`), D13 amended
(`12a_woneb1`), D11 amended (`03a_woneb13`). The idea's part-review still describes the
extension's old round folder (`round.yaml`, `base`, one copy per member, `merged/`); the decision
FQ-11 of 2026-11-25 replaces it (§ 2.1) and the todos already state the new layout.

**Webwork is on hold.** No Webwork todo runs until tom_forge's last restructuring step and the
ai_runtime quest's **runtime specification** are done (FK-9, FK-16; `03a_woneb1`, blocked by
tom_forge `forgemods5`, and waiting for "the ai_runtime runtime specification (no todo id yet)").
Wave 1b1 needs neither the runtime nor tac; wave 1b2 (AI run tabs, team messaging, review through
messaging) "assumes the runtime is complete" (`webwork_wave1_plan.md`).

**What changed since round 4's input (2026-11-20):**

1. Two review areas, **Review** (the reviewer's) and **Team Review** (the coordinator's)
   (FQ-5, FQ-8), both in wave 1b1 (OR-21).
2. **One review folder layout for everyone** — the runtime's round operations, the extension's
   round tools and Webwork (FQ-11 (a)); vscode_extension `04c_woneb4`, tom_specs `05c_woneb1`.
3. **Channels besides tac**: export / import of files in wave 1b1, files dropped into the
   folder by hand, *Send by email* through the system's mail client in wave 1b2 (FQ-9 (a)).
4. A navigation contract for the review component on both routes: *reveal*, *reading
   position*, *changed* (OR-19; vscode_extension `04c_woneb3`, tom_forge `05b_woneb1`).
5. The messaging UI as a module **`tom_messaging_ui` in `tom_modules`** (C21, Q-8 (a)).
6. An install package **`tom_tool_installer`** that also takes the Claude Agent SDK server
   install (FQ-3 (a); tom_forge `03b_woneb2`).
7. Todo ids renamed: `03_woneb13/14` → `03a_woneb16/17` (D39), `03_woneb10` → `03a_woneb13`
   (D11), `wwreplan1` → `03a_woneb1`.

---

## 2 Team review and review document bundles — the complete need

### 2.1 What a review is in Webwork

| Concept | As planned | Source |
| --- | --- | --- |
| **Review set** | `reviews/<review-name>/review.yaml`: the documents (files, Webwork documents and sections, TomSpecs documents in YAML or Markdown), the members, the coordinator, the rounds, the *sent* marks | FQ-11 (a); `09_woneb3`; `03a_woneb17`; vscode_extension `04c_woneb4` |
| **Round** | one folder per pass, `round-<n>/` (`round-2/` … for a second pass of the same review) | FQ-11 (a); `04c_woneb4` |
| **Base** | `round-<n>/outbound/base/<files>`: the documents as sent to everyone, the merge base | FQ-11; Revision 4 |
| **Per-member copy (optional)** | `outbound/<member>/<files>` only when that member gets something different ("Usually the files go out identical to everyone") | FQ-11 answer; Revision 4 |
| **Returned copy** | `returned/<member>/<files>`: dropped in by hand, imported, or delivered by messaging | FQ-11; `09_woneb3` |
| **Merged result** | `consolidated/<files>` and `merge-report.json` | FQ-11; `09_woneb3` |
| **State** | read from the folder: *prepared* (base or member folder present), *sent* (recorded in `review.yaml`: by hand in 1b1, by the channel in 1b2), *returned* (files in `returned/<member>/`), *valid* (structure check of the copy against the base), *consolidated* (merged files present, every conflict decided) | FQ-11; `09_woneb3`; `04c_woneb4` |
| **Where it lies** | a storage location of the user's choice, default `reviews/` at its root; any storage tier (local folder, GitHub, git through `tom_core_storage`), "a GitHub location lets a team share it" | FQ-11; FQ-1 (a); `09_woneb3` |
| **Coordinator (owner)** | the one who starts the review; works in **Team Review**: sets and rounds, sending, tracking per reviewer, the returned copies, consolidation (merged document, conflicts, votes) | FQ-5, FQ-8; `09_woneb3` |
| **Reviewer** | works in **Review**: the reviews waiting for me (rounds I was sent a copy of; documents I marked *Review this*, a quest process's review documents included), the document, outline and items, **Send back** to the coordinator "through the channel it came by" | FQ-5, FQ-6, FQ-8; `09_woneb2` |
| **Members and roles** | a member is `memberId` (`[a-z0-9_]+`), display name and role (the extension's `RoundMember`); the team comes from the document's review team, else the solution blueprint's (`review-team.ts`) | extension `reviewRound.ts`, `review-team.ts` |
| **Guests** | a copy from somebody not on the team; named (name and role) in `review.yaml` before the merge | `09_woneb3`; extension user guide |
| **Merge** | SOM § 11.9.8's team round through `tom_som_dart_runtime`: marks with authors and votes, tracked changes and inline comments as marks, individual answers, conflict blocks; edge case: a copy against an older base reports a structure mismatch | `09_woneb3`; part-review |
| **Conflicts and decisions** | decided in the component's consolidation view (one button per alternative, keep base, rewrite, keep open; the team-answer editor prefilled with the most chosen option; *Next unresolved*) | tom_forge `05b_woneb5`; extension user guide |
| **Next round** | a new `round-<n>/` under the same review; the extension's `round.yaml` also keeps `nextRound` (guests accepted for the next round only) | FQ-11 (c) rejected; `reviewRound.ts` |
| **Old layout** | the extension's current round folder (`round.yaml`, `base.<ext>`, `alice.<ext>`, `merged/`) is read and converted on first use | FQ-11 (a); `04c_woneb4` |

Not planned in Webwork (checked by search: no "deadline" in the idea, the todo file or the
decisions document): **a deadline for a round** and **tac reminders** to reviewers. A card's
*Remind me* makes a reminder item in Webwork itself (`13_woneb9`), not a tac reminder.

### 2.2 What is sent to whom, and when

| Event | From → to | What | Wave 1b1 | Wave 1b2 | Source |
| --- | --- | --- | --- | --- | --- |
| A round goes out | coordinator → each member | the base (or the member's own folder); per document either a **Webwork copy** (the item or section subtree as a `.webwork.zip` part bundle, UUIDs kept, the version sent recorded as the base) or the **rendered** form (Markdown, HTML, PDF through the one serialize visitor), password sections withheld; TomSpecs and Markdown documents as their files | exported file, sent "by any means, an email by hand included"; *sent* marked by hand | through tac "in a thread attached to the round"; *sent* recorded by the channel; *Send by email* opens the system's mail client or share sheet with the file attached | `09_woneb3`; `13_woneb9`; `13_woneb10`; FQ-9 |
| A reviewer returns a copy | member → coordinator | the annotated copy | an export file the coordinator imports into `returned/<member>/` | **Return copy** in the same thread; the coordinator's Webwork writes it into `returned/<member>/` "so the merge sees no difference from a copy made in the storage" | `09_woneb2`; `13_woneb10`; part-review |
| Arrival | tac → coordinator | "review copy returned" entry with Open and Merge in the right panel; a badge with the number of open reviews on the Review icon | — | yes | `13_woneb8`; `09_woneb2` |
| Merge done | coordinator's Webwork → tac | "the server is told so its blobs can go; otherwise they stay until their lifetime ends" | — | yes | `13_woneb10`; part-messaging |
| Merged result | — | stays in `consolidated/`; no source says that it is sent to the members (*unverified* whether it ever is) | — | — | `09_woneb3` |
| A member with storage access | — | works on the copy in the shared reviews folder; nothing travels | yes | yes | part-review |
| Reference instead of a copy | coordinator → member who can open the same storage | `[<document-locator>]#<id>` | — | yes | `13_woneb9` |

**The bundle.** What a round carries is a *set* of documents (review set), and each Webwork
document travels as a `.webwork.zip`. No Webwork source says how a round with several documents
travels through tac — one message with several blobs, or one archive — nor which metadata beside
"a thread attached to the round" and "the version sent recorded as the base" travels with it
(D40 is not written). Asked in § 4, PQ-W1.

**Identity on a returned copy.** The folder is `returned/<member>/`, named by the review member
id; a copy returned through tac comes from a tac user id. No Webwork source says how one is
mapped to the other. Asked in § 4, PQ-W2.

### 2.3 Offline, across machines, over the internet, outside version control

- **Who uses tac at all:** only members without access to the documents' storage ("the business
  reviewer", "people … who cannot reach the repositories the documents live in"); members with
  access work in the shared folder (part-review, part-messaging).
- **Desktop to desktop only** in wave 1b2: "Reviewers on the web, the phone or the tablet join
  with the server-side runtime of a later wave" (`13_woneb10`, note); Webwork names wave 3 for
  the server side (WW-17 still holds).
- **Offline:** an outgoing message waits in a device-local outbox with its request id; the cached
  history is read-only while the server cannot be reached; "assists and sending copies do not
  [work offline]" (part-messaging, part-review *Edge cases*; `13_woneb6`). Where the cache and the
  outbox live is PQ-52.
- **Coordinator offline / server dropped the base:** "the round folder still has it; the merge
  runs against it" (part-review *Edge cases*; `13_woneb10`).
- **Not in the same version control:** the reviews folder may lie in any storage tier, not
  necessarily git (FQ-1, FQ-11). Webwork's plan has no commit step for a returned copy: writes go
  "into the device-local copy first and reach the storage with the user's explicit Save"
  (part-review, *Both routes write the same way*).
- **Over the internet:** only through a runtime ("no direct tac connection from a browser or a
  phone", `12a_woneb2` note); for the desktop the local runtime reaches the team's tac server.

### 2.4 Who stores what

| Store | Holds | Source |
| --- | --- | --- |
| Webwork's document storage (local folder, GitHub, git) | the reviews folder: `review.yaml`, bases, member copies, returned copies, consolidated documents — "the round folder keeps the copies for good" | FQ-11; part-messaging |
| Version control | only when the chosen storage location is git or GitHub | FQ-1; FQ-11 |
| The device (Webwork) | the conversation cache and the outbox (device-local, like the D3 § 4 journal); the messaging account (user id, e-mail, server address, team token) in the settings container, "never in a document, log or export" | `13_woneb6` |
| tac | user messages (1 year by default, a team can change it); blobs (7 days by default, 30 at most; "a process can pin its blobs (review sets) while it runs") | `12a_woneb2` note; `13_woneb6` note |

The token's place differs from the Project Idea (CP.13: "the team tokens of a user are the
runtime's", CS.11); WW-14 still holds in the webwork todo (`13_woneb6`), which webwork has not
been told yet.

### 2.5 Size limits and encryption

- **Limit:** "a copy over the server's size limit refused before sending with the alternatives
  offered" (reference or rendered form) (`13_woneb9`; part-messaging *Too large*). No Webwork
  source gives a number. The protocol as built has a message payload of at most 1 MiB and no blobs
  (`webwork_requirements.md` WR-5). A Webwork document can hold image assets (D21); whether
  review bundles regularly pass a few MiB is *unverified*. The number belongs to PQ-56 (N-37).
- **Encryption:** on the wire only, not end to end, not at rest (part-messaging; WR-3). Content
  of encrypted (`.webwork.kdbx`) documents is sent by the user's choice; password sections are
  never sent, a reference to one is refused (`13_woneb9`). "Protecting sensitive data" and "real
  authentication" are later todos (part-messaging *Later*; `deferred.webwork.md`).

### 2.6 What the review component shows

- **Reviewer (Review area):** the document on route 1 (the extension's MD Browser page in
  Webwork's webview, `tom_md_browser`, `09_woneb5`) or route 2 (the Dart component in tom_forge,
  working name `tom_md_browser_editor`, `05b_woneb1` …), TomSpecs YAML in the TomSpecs editor
  (`09_woneb4`); questions, comments, inline comments, marks, tracked changes (on by default when
  reviewing), proposed answers; a right-panel **Review tab**: the outline (open items per heading,
  the reading position) and the review items in document order, filtered by kind, open only and
  member; reveal on click, next / previous, quick actions (accept / reject a change or mark,
  resolve a comment, accept / discard a proposed answer, jump into an answer field), all through
  `tom_som_dart_runtime` (`09_woneb2`; OR-17, OR-18).
- **Coordinator (Team Review area):** the round's members with their state; a returned copy
  read-only or the merged document with its conflict blocks; a right-panel Team Review tab with
  outline, conflicts and votes (`09_woneb3`); chips per member, votes on base marks, individual
  answers, conflict choices, accept / reject per author (tom_forge `05b_woneb5`).
- **The navigation contract** on both routes: *reveal* an item, *reading position*, *changed*
  (OR-19; vscode_extension `04c_woneb3`; tom_forge `05b_woneb1`).
- **Assists** (Grill me, Explain in detail, proposed answers) in wave 1b2, "sent as prompts into
  the Review area's run with the extension's assist prompts" (`13_woneb5`).
- **Where it is built:** outside this product — route 1 is the extension's page, route 2 and the
  TomSpecs editor are tom_forge's (C10 "F", component placement § 2.1). Confirmed again by the
  decisions of 2026-11-25 (OR-19, OR-20). PQ-43 is unanswered.

### 2.7 Comparison with the Project Idea

Verdicts: **covered**, **differs**, **missing**, **decided** (a product owner's decision in the
webwork quest that the Project Idea does not yet reflect — to be applied, not asked).

| # | Need (source) | Project Idea | Verdict | Proposal |
| --- | --- | --- | --- | --- |
| R1 | One review folder layout for the runtime's round operations, the extension's round tools and Webwork; old folders converted on first use (FQ-11 (a); vscode_extension `04c_woneb4`; tom_specs `05c_woneb1`) | CV.13 ("the description of the round, the base, each member's copy, the merged result"); CR.5 ("team review rounds on documents"); glossary *round folder* | **decided**, missing in the text | New item **CV.17** (text below) |
| R2 | The review set is `review.yaml` in the reviews folder, with numbered rounds under one review, written by every tool (FQ-11) | CV.5: "What is under review … is defined by the application and kept in the documents' storage (Webwork plans a small YAML file there …)" | **differs** | CV.5, last sentence: "What is under review, its members, coordinator and rounds is the review's `review.yaml` (CV.17), the same for every application and the runtime's round operations." |
| R3 | The round's state *prepared, sent, returned, valid, consolidated*, read from the folder; files may be put in by hand (FQ-11; `09_woneb3`) | CV.12 step 5 ("the round is marked as merged"); nothing on the other states | **missing** | New item **CV.18** (text below) |
| R4 | Copies also travel by export / import, by e-mail through the system's mail client and by hand into the folder; tac is the channel for members without storage access (FQ-9 (a); `09_woneb3`) | CV.11: "Nobody carries files by hand: the step of a team review in which the copies are collected is done by the exchange." | **differs** (decided in webwork) | CV.11: "tac carries the documents of a review round out to the members and their copies back, for members who reach the round only through tac. A copy that arrives by another way (a file sent by hand, a shared folder) counts the same once it is in the round folder (CV.18)." |
| R5 | A member may get files different from the base (`outbound/<member>/`, optional) (FQ-11 answer) | CM.2 *review request* ("the set of documents"); CV.12 step 1 ("sends a review request with the document set to every member") | **missing** (detail) | CV.12 step 1: "… with the document set to every member — the base, or the member's own files where the round has them (CV.17)". |
| R6 | Webwork creates and merges its own rounds through `tom_som_dart_runtime` (`09_woneb3`) | CV.12 steps 1, 3, 5 | covered | — |
| R7 | Blobs: hash, limit known before sending, lifetime, pin, extend, release (WR-5; `13_woneb9`) | CV.1 … CV.4, CV.14 | covered | — |
| R8 | The round's blobs stay "until the round is merged or their maximum lifetime ends" (part-review; part-messaging; WR-5 "until it is merged or the maximum is reached") | CV.14: "A round's blobs are kept until the round is merged"; D-29: "a review set is a named set of pinned files" | **differs** (no maximum in CV.14) | Asked: PQ-W4 |
| R9 | A round's set of several documents, each Webwork document a `.webwork.zip` (`09_woneb3`; `13_woneb9`) | CV.1 (one file = one blob); CM.2 (the set of documents) | **missing** (how a set travels) | Asked: PQ-W1 |
| R10 | The reviewer's list "rounds I was sent a copy of", with their state (`09_woneb2`) | CP.36 ("the review request and its return"); CM.2 | **missing** (no query) | CP.36, add: "the review requests addressed to the user, open or returned, across conversations". |
| R11 | *sent* recorded by the channel per member (`09_woneb3`; FQ-11) | CM.13 (request id); nothing on what the sender learns | **missing** (small) | CP.36, add: "for a review request, per member whether tac accepted it for delivery and whether the member has opened it". The second half is not in Webwork's sources — leave it out if not wanted. |
| R12 | A copy returned twice, or by someone it was not sent to: shown, not merged (`13_woneb10`) | CV.9 | covered | — |
| R13 | Deadline and reminders of a round | CM.2 (*review request* carries "the deadline"), CM.4, CV.12 step 4 | **beyond Webwork's need** (backed by S1, not by Webwork) | none; Webwork plans none and would not use them in wave 1b2 |
| R14 | Guests named in `review.yaml` before the merge (`09_woneb3`) | CV.12 (guests return "by another way"), CV.16 | covered | — |
| R15 | `returned/<member>/` named by member id; a tac return comes from a tac user (§ 2.2) | CV.12: "how the member id of a review round (CP.13) relates to the user id in tac" left to the Blueprint | open | Asked: PQ-W2 |
| R16 | A reviewer without a repository works on a desktop in wave 1b2 (`13_woneb10`) | CV.15 | covered | — |
| R17 | Messaging and documents through the runtime (CI.4) | CP.36; WR-4, WR-5 rows of `TAC-WEBWORK` | covered | — |
| R18 | Team = tac team, invitation with a one-time password, team token (`12a_woneb2`; `13_woneb6`) | CI.6 … CI.9; D-54 | covered; token place **differs** (§ 2.4) | No change here; tell webwork (WW-14) |
| R19 | Encryption on the wire only (part-messaging) | CI.16, CI.17 | covered | — |
| R20 | The review component outside this product, in two routes; the TomSpecs editor in tom_forge (OR-19, OR-20; C10) | CU.6 *Review*, CU.9, SC-18, CK.2, R-19; PQ-43 | **differs** | Asked: PQ-W3 (extends PQ-43) |
| R21 | The navigation contract *reveal / position / changed* (`04c_woneb3`; `05b_woneb1`) | CU.9 ("The protocol … is an input for the component's interface") | covered only if the component is built here; otherwise not this product's | Follows PQ-W3 |
| R22 | Assists through the runtime with the extension's assist prompts (`13_woneb5`) | not named (no "Grill me" in the Project Idea; CR.5 lists team review rounds, not the assists) | **missing** | New item, in `RT-HOLDS` beside CR.5: "The runtime carries the review assists the extension has (Grill me, Explain in detail, proposed answers) with their prompts, so every host sends them into a run of its own." (Overlaps with the extension inventory.) |
| R23 | A quest process's review documents reach Webwork's Review list (FQ-6 answer) | CP.13 ("opening a document for reading or review") | covered (in Webforge) | — |
| R24 | WR-1 … WR-7 | `TAC-WEBWORK` | covered as round 4 left it | Add to the WR-5 row: "the round folder layout of CV.17" |

**Proposed item texts:**

- **CV.17** *The layout of a review.* A review lies in a folder `reviews/<review-name>/` in a
  storage location beside the documents (default `reviews/` at its root): `review.yaml` names
  the documents, the members, the coordinator, the rounds and what was sent; each round is a
  folder `round-<n>/` with `outbound/base/` (the documents as sent to everyone, the base of the
  merge), `outbound/<member>/` only where a member gets something different, `returned/<member>/`
  (what each member sent back) and `consolidated/` (the merged documents and the merge report).
  The runtime's round operations, the VS Code extension and Webwork write and read this one
  layout; a round folder in the earlier layout (`round.yaml`, the base, one copy per member,
  `merged/`) is read and converted on first use. (<- S25: webwork FQ-11; S23: vscode_extension
  `04c_woneb4`, planned)
- **CV.18** *The state of a round* is read from its folder: prepared (the base, or a member's
  own files, is there), sent (recorded in `review.yaml` by the channel that sent it, or by hand),
  returned (files in `returned/<member>/`), valid (the copy's structure fits the base),
  consolidated (merged documents there and every conflict decided). A file put into the folder by
  hand counts like one that arrived through tac. (<- S25: webwork `09_woneb3`, FQ-11)

---

## 3 Everything else Webwork needs from the first version

Status of the Webwork todo in brackets. Wave 1b1 needs nothing from this product; everything
below is wave 1b2 or later unless marked.

| Need | Webwork source | Project Idea | Verdict |
| --- | --- | --- | --- |
| Webwork's own AI as a runtime that serves no quest, instance name `webwork-app` | `12a_woneb1` (not-started), `13_woneb1` (blocked) | CR.6, CR.29, T2; PQ-51 | open (PQ-51 stands) |
| One run per registered area, named after it, in `default@<run>`, created on first use; the area's tool set per prompt | `12a_woneb1`, `13_woneb1` | runs (`RT-RUNS`), CT.1, CT.4 | covered in general; the naming is Webwork's |
| A run bound to a quest folder runs in that quest's runtime | `12a_woneb1` | T2; PQ-36 | vague (WW-9 still holds) |
| Queue at the end, queue next, update to the running prompt; *New conversation* | `12a_woneb1`, `13_woneb2` | CR.15, CR.16, CR.18 | covered |
| *Review each prompt* / *Work silently* per run, "device state, starting in Review" | `13_woneb2` | CR.17 ("kept by the runtime") | differs (WW-10 still holds) |
| AI result tiles: Undo per prompt with its confirmation, Apply / Discard in two places | `13_woneb3` (not-started) | CU.8 (marks of a prompt waiting to be applied or discarded); `RT-TOOLS` (the runtime records what a tool wrote, for undo) | covered as far as the runtime is concerned; Undo is the host's |
| The D35 document tools as host tools, executed inside the prompt's undo groups | `13_woneb1`; `qavs_wwworkbench-1` (blocked) | CT.1, CT.4; N-18 (not through the MCP server) | covered |
| Trail written by the runtime; bounded appending Markdown for the trail and every Output channel | `12a_woneb1`, `13_woneb4` | CU.7 | covered |
| Trails of encrypted documents in memory only (D13 § 12.7) | `12a_woneb1` | CR.24, N-23 | covered |
| Review assists | `13_woneb5` | — | missing (R22) |
| Today's AI in wave 1b1 (`tom_ai_trail_ui` over `tom_llm`), retired in 1b2 | `06_woneb9`, `13_woneb4` | E-20; PQ-44 | open (PQ-44); note: component placement C22 lists the AI run tabs as "existing modules" (`tom_agentic_ui`, `tom_ai_trail_ui`) while `13_woneb2` takes them from `tom_ai_runtime_ui` — an inconsistency inside webwork |
| Messaging account, team, invitations, presence, the stream with reconnect and catch-up, read state | `13_woneb6` (blocked) | CI.3, CI.6 … CI.9, CM.6, CM.9, CM.10 | covered; token place differs (§ 2.4) |
| Conversation cache, outbox, search over the cache | `13_woneb6`, `13_woneb7` | CM.9, CM.13; PQ-52 | open (PQ-52 stands; answer (b) removes Webwork's own cache) |
| Messaging area, right-panel section, arrivals, unread counts, mute, threads attached to a document or round | `13_woneb7`, `13_woneb8` | CM.7, CM.8, CM.10, CU.15, CU.16 | covered; where the components are built: PQ-W3 |
| Sending in three forms; the card's Open, Save into…, Merge, Remind me / Make todo | `13_woneb9` | CV.8, CV.9, CM.3, CU.16 | covered |
| A message turned into an item with the anchor `msg:tac/<…>/<messageId>` | `13_woneb9`, `12a_woneb2` write `<server-group>`; the idea writes `<team>` | CM.12 (`<team>`) | covered; the two todos still have the old form (WW-16 still holds) |
| Merging a returned Webwork copy by UUID against the recorded base | `13_woneb9` | — (Webwork's own D1 § 8.3) | not this product's |
| System notifications for reminders and appointments, local only; no push service on the phone | `06_woneb6`, `10_woneb4`; DPPHONE-4 | CM.6; PQ-49 | open (PQ-49 stands) |
| AI and messaging on the web, the phone and the tablet through a server-side runtime, in a later wave (wave 3) | `10_woneb1`; DPPHONE-5; notes on `13_woneb*` | CR.108, L-8, T8; PQ-38, PQ-41, PQ-49 | covered as later; open questions stand |
| Webforge's Webwork runtime registers as `webwork-app` with `hasQuest: false`, may take part in the claims, may publish a Webwork MCP endpoint of its own | `qavs_collab_b-1` (blocked by ai_runtime `ww_d_workbench-10`, `ww_c_collab-3`, `ww_f_collab-2`) | PQ-51; CA.23 | open (PQ-51); the endpoint vague (WW-8 still holds) |
| The full tac server (customers, keys, quotas, admin API, TLS at a reverse proxy); a small team is one customer | `12a_woneb2` note | CA.26 … CA.28 | covered |
| Uniform todo fields between Webwork and the extension: reminder fields (done), `role` and `guidelines` with several choices per aspect | `wwremind1` (done 2026-11-23), `05a_woneb9` (not-started) | line 556 and E-2: "`tom_todo_model` 4.2.0" | **differs**: `tom_todo_model` is 6.0.0 on disk (`tom_ai/modules/tom_todo_model/pubspec.yaml`; `05a_woneb9` names 6.0.0, vscode_extension `gsel20`) |
| One installer for external tools, the Claude Agent SDK server install moved into it (`tom_tool_installer`, pure Dart, and `tom_tool_installer_ui`) | FQ-3 (a); tom_forge `03b_woneb2` (not-started) | CR.40 … CR.43 (provider SDKs installed by the runtime on request); PQ-37 | **differs**: asked in PQ-W6 |
| The extension's collaboration and feature tools (resources, leases, features) taken into Webwork's todos | `caf_17a` (blocked) | `TAC-COORD`; S3: Webwork does not need leases for messaging | covered; nothing new for this product |
| The two messages ai_runtime owes webwork (the todos covering WR-1 … WR-7, then "runtime fully built"); Webwork's `blocked_by` still names ai_runtime `12b_woneb1` … `3`, `tac_webwork-6`, `ww_*` (all not-started there) | notes on `12a_woneb*`, `13_woneb*`; `03a_woneb1` | `DEL` | open (WW-22 still holds); Webwork now also waits for the runtime **specification** as a document (`03a_woneb1`) |

---

## 4 Questions for the product owner

Real choices only. Decided in the webwork quest on 2026-11-25 and therefore **not** asked (to be
applied): the one review layout (R1, FQ-11), the channels besides tac (R4, FQ-9), the two review
areas (FQ-5, FQ-8). PQ-49, PQ-51 and PQ-52 stand as written; Webwork's sources add nothing that
changes their options.

### PQ-W1 — how a round's documents travel through tac (new)

A review round sends a *set* of documents (CV.10; `review.yaml`), each Webwork document as a
`.webwork.zip` (`09_woneb3`), and a member may get files of their own (`outbound/<member>/`).
CV.1 makes one file one blob; CM.2's *review request* carries "the set of documents". Nothing says
whether a set is several blobs or one.

- (a) One archive per member and round: the base (or the member's folder) packed into one blob;
  the return is one archive of `returned/<member>/`. Simple to send; every member's archive is a
  separate blob unless they are byte-identical.
- **(b)** One blob per file: the review request lists every file with its path inside the round
  (`outbound/base/…` or `outbound/<member>/…`), its hash, name, media type and size; the return
  lists the files of `returned/<member>/` the same way; a Webwork document is one file (its
  `.webwork.zip`). An identical base is stored once for all members (CV.1), and a reviewer can
  return only what changed.
- (c) Left to the application: tac carries opaque blobs; how a set maps onto them is each
  application's convention.

*Recommendation:* (b) — it uses CV.1's content addressing as intended, matches the folder layout
file for file, and lets the size limit (CV.2) apply per file. *Replaces / extends:* new; touches
CM.2 and CV.1.

### PQ-W2 — the review member id and the tac user (new; replaces CV.12's open point)

CV.12 leaves to the Blueprint "how the member id of a review round (CP.13) relates to the user id
in tac". The folder is `returned/<member>/`, attributions are `{@<memberId>}`, member ids are
`[a-z0-9_]+` (the extension's `MEMBER_ID`); a copy returned through tac arrives from a tac user.

- (a) tac's team member record carries the person's review member id, set when they join; every
  application uses it.
- **(b)** The review's `review.yaml` names, per member, the member id and the tac user (id and
  e-mail); the review request tells each reviewer the member id to sign with; the coordinator
  files a return under the member whose tac user sent it.
- (c) The member id is derived from the tac user id by a fixed rule.

*Recommendation:* (b) — the mapping lives in the record of the review, works for members who
never use tac, needs nothing new in tac's people model, and keeps member ids stable across
rounds. *Replaces:* the open point at the end of CV.12.

### PQ-W3 — which UI components this product builds: review and messaging (extends PQ-43, touches PQ-44)

PQ-43 asks where the review component is built. Since then the product owner decided in the
webwork quest (2026-11-25): the review navigation is built into the extension's page and
tom_forge's Dart component (OR-19, OR-20), and the team messaging UI is a module
**`tom_messaging_ui` in `tom_modules`** (component placement C21, Q-8 (a), there assumed to work
"over tac's Dart client"). The Project Idea has a **Review** and a **Messaging** group in
`tom_ai_runtime_ui` (CU.6, CU.9, CU.16) and says that an application reaches tac only through
its runtime (CI.4, CP.36).

- (a) Both here, in `tom_ai_runtime_ui`, as CU.6 says; webwork and tom_forge are told to take
  them.
- **(b)** Both outside this product: the review component as the two routes of the webwork and
  tom_forge quests (PQ-43 (b)); the messaging components as `tom_messaging_ui` in `tom_modules`,
  working over the runtime client SDK's messaging commands (CP.36), not a tac client. CU.6 loses
  both groups (it may keep the review request card in the Asks or Conversation group); trc embeds
  both. This product delivers the runtime and tac sides and the runtime client SDK commands they
  use.
- (c) Review outside (PQ-43 (b)), messaging here: `tom_messaging_ui` is not built; Webwork takes
  the Messaging group of `tom_ai_runtime_ui`.

*Recommendation:* (b) — it follows the product owner's decisions in the webwork quest of
2026-11-19 and 2026-11-25, keeps `tom_ai_runtime_ui` free of Tom Forge (CU.3), and corrects only
one thing in Webwork's decision: the module works over the runtime client SDK (CI.4).
*Extends:* PQ-43; PQ-44 decides the agent views.

### PQ-W4 — how long a round's blobs stay on the tac server (new)

CV.14: "A round's blobs are kept until the round is merged"; D-29: "a review set is a named set of
pinned files". Webwork (part-review, part-messaging) and the requirement (WR-5) say: kept "until
the round is merged or their maximum lifetime ends" — the round folder keeps the copies for good.

- (a) As CV.14 reads: pinned until the round is marked merged, with no maximum; the team's quota
  is the only bound.
- **(b)** Pinned until the round is marked merged, but at most 30 days from the request; the
  coordinator's application can extend it (CV.14's extend operation) while the round is open;
  after that the round folder is the only copy.
- (c) Not pinned: like any message's blobs (7 days by default, 30 at most), extended by hand.

*Recommendation:* (b) — it is what the requirement and Webwork state, keeps tac from becoming a
file server (O-7), and a forgotten round frees its space by itself. *Replaces / extends:* new;
CV.4, CV.14.

### PQ-W5 — the first usable state includes the review exchange (extends PQ-57)

PQ-57 (b) proposes one thin path run early: T1 with the runtime inside the new extension, the
local tac service, F1, F2, F3, F8. The product owner's instruction (a) of this round says "We must
provide Webwork with what it needs for the team review features and sending review document
bundle"; Webwork's wave 1b2 waits until "the runtime is complete" (`webwork_wave1_plan.md`) and
Webwork is on hold until the runtime specification exists (`03a_woneb1`).

- (a) PQ-57 as proposed; Webwork's slice comes with the whole product (D-32).
- **(b)** PQ-57 (b), and a second thin path in the same early state: a team review (F6) between
  two desktops through a tac server — the runtime that serves no quest, the runtime client SDK's
  messaging and blob commands (CP.36), teams with invitations, user messages, blobs with
  pinning, review request and return; webwork is told when it works, so wave 1b2 can start before
  everything is there. `tac/2.0` stays one specification built in one go (D-21, CA.36).
- (c) No early state at all (PQ-57 (c)).

*Recommendation:* (b) — it puts the one feature the product owner names for Webwork on the path
that is tested first, without fixing an order of the component groups (D-45). *Extends:* PQ-57.

### PQ-W6 — who installs the provider SDKs and Node (extends PQ-37)

CR.43: "Provider SDKs are installed on request, when a profile first [needs them]" — by the
runtime. The product owner decided in the webwork quest (FQ-3 (a)) one installer package in
`tom_ai/modules`, `tom_tool_installer` (pure Dart) with `tom_tool_installer_ui`, which takes "the
Agent SDK server install from `tom_core_agentic`" and later "other providers' SDKs", with publisher,
terms, exact version and a confirmation for every install (tom_forge `03b_woneb2`). The runtime is
a Node program (N-24); a Dart installer cannot run inside it.

- (a) The runtime installs its provider SDKs itself (CR.43) and shows the same facts and
  confirmation as `tom_tool_installer` (publisher, terms, version); `tom_tool_installer` keeps the
  tools outside the runtime (LibreOffice and the like); the Agent SDK install in
  `tom_core_agentic` retires with Webwork's move to the runtime (`13_woneb4`).
- **(b)** As (a), and `tom_tool_installer` installs the runtime itself (and Node, if PQ-37 makes
  the installation bring or require it) for a Dart host that is not VS Code, through one
  descriptor the runtime installation publishes; the runtime installs only its provider SDKs.
- (c) Every install, the provider SDKs included, goes through `tom_tool_installer` in the host;
  the runtime only detects what is there and reports what is missing.

*Recommendation:* (b) — one installer for the hosts outside VS Code (Webwork, Tom Forge) with the
terms rule the product owner decided, while the runtime stays the one place that knows which
provider SDK a profile needs (CR.43). *Extends:* PQ-37.

---

**Messages owed to webwork once the round is through** (not questions; listed for `DEL`): the
token is the runtime's (CP.13, CS.11) — `13_woneb6`; the review option is the runtime's (CR.17) —
`13_woneb2`; the message anchor is `msg:tac/<team>/<messageId>` — `12a_woneb2`, `13_woneb9`; the
covering todos for WR-1 … WR-7 replacing the `12b_woneb*`, `tac_webwork-*` and `ww_*` entries in
Webwork's `blocked_by`; the runtime specification as the document `03a_woneb1` waits for.
