<!-- snapshot of _ai/quests/ai_runtime/webwork_requirements.md, 2026-11-19 -->
# What Webwork needs from the Tom AI Runtime and tac

What Webwork needs from the Tom AI Runtime (tar) and the Tom Agent
Coordination service (tac), each requirement with what the current
implementation has and what is missing. It comes from the webwork quest's
idea [webwork_redesign](../webwork/ideas/webwork_redesign/webwork_redesign.md)
(its parts on messaging, the bottom panel and the wave plan), for Webwork's
**wave 1b2**.

**This is a requirement statement, not a commitment.** The ai_runtime
specification is being written; it decides what tar and tac become, in what
form and when. This document is input to it (the todo
`webworkreq1_akrn-webwork-requirement`), and the todo group `tac_webwork-*`
at the end of this quest's todos turns the tac part into features as the
current tac implementation stands. Where the specification decides
differently, the specification wins and Webwork adapts.

## Why Webwork needs it, and when

Webwork's redesign splits its wave 1b in two:

- **Wave 1b1** is everything that does not depend on the AI runtime or tac.
  It is built, finished and released on its own, also when nothing here is
  ready (an interim release).
- **Wave 1b2** is what needs tar or tac: the AI run tabs of the bottom panel
  over the runtime, the Output view over the runtime's trail components, and
  team messaging over tac. It adds no AI feature beyond what wave 1b already
  planned. It waits for the work this document describes.

Webwork's team messaging is meant for a small team, usually on the VPN, whose
members know and trust each other. It is a chat-like conversation UI and,
above all, the channel through which documents travel for review to people
without access to the repositories (business reviewers). It starts simple:
identification instead of authentication, encryption on the wire only.

## The requirements

### WR-1 — tac reachable as a server by a small team

**Needed.** One tac service that the members of a Webwork team reach from
their machines over the network (the VPN first), from Webwork on the desktop,
in the browser and on the phone. A Webwork team is one agent group on it.

**Exists.** Only the local mode: one service per machine and OS user on
`127.0.0.1:19890`, with one bearer key in `~/.tom/coordination/local.key`
(mode 0600) that only the same OS user can read. `config.yaml` already lets
the service bind another host, but nothing else of a server is there. The
TAC specification (`tac/1.0`, § 3.1, § 3.12, § 9) describes the server:
customers, access keys stored as salted hashes, quotas, an admin API; the
groups are created by that admin API. The store already partitions by group
and records a `customerId`. The todos `ww_g_collab-2` (the server) and
`ww_g_collab-3` (the server backend in the runtime's client) plan it, and
al_the_bear's `collab_d-2` runs it on bigbeast.

**Missing.** A server mode that serves several machines: a way to create a
team's group and hand its members the means to reach it, a per-group access
key (or one per member) instead of the machine's local key, CORS for a
Webwork running in a browser, and a long-running deployment. Customers,
quotas and the full admin API are not needed for the first Webwork team.

### WR-2 — identification by user id and email on connect

**Needed.** When Webwork (or a runtime acting for a person) connects to tac,
it sends the person's **user id and email address**, and that is all: tac
records who is there and uses it to address and attribute messages. There is
no real authentication yet; it comes later, probably for tac as a whole.

**Exists.** tac knows runtimes, not people. A runtime registers with
`runtimeId`, `kind` (`vscode` / `webforge` / `runtime-server`), `host`,
`workspace`, `quests` and `hasQuest` (false for Webwork's own runtime,
registered as `webwork-app`). Presence is an open message stream per
`runtimeId`. Nothing in `hello`, `register` or a message's `origin` names a
person.

**Missing.** A user (id and email) carried on connect and stored with the
registration; a message origin that names the user; a list of the people of
a group who are present or known. And a way for a client that is **not an AI
runtime** — Webwork in the browser and on the phone has none — to register,
hold a stream and be present.

### WR-3 — encryption on the wire only

**Needed.** Traffic between Webwork and the tac server is encrypted in
transit. Nothing more: no end-to-end encryption, no requirement on encryption
at rest from Webwork (FO-20 stands). What a user sends is the user's
decision; protecting sensitive content in messaging is a later piece of work
in the webwork quest that may need a specification of its own.

**Exists.** Plain HTTP and WebSocket on loopback; the local service needs no
transport encryption. The TAC specification and `ww_g_collab-2` name
transport encryption for the server.

**Missing.** TLS (HTTPS and WSS) on the server, in the service or through a
reverse proxy in front of it, with a certificate the team's devices trust.

### WR-4 — user messages

**Needed.** Messages between people of a group, as FO-7 plans them: direct
messages and group conversations, and threads attached to a document or a
review round; Markdown text; read / unread per user; delivered live while
connected and on reconnect (a client asks for what it missed since a point);
stored with a retention per group; a Webwork client keeps an outbox while
offline, so a send must be safe to repeat.

**Exists.** Messages between runtimes, addressed to **quests**, with a free
`type` and a free JSON `payload` the service never reads (at most
`maxPayloadBytes`, 1 MiB by default). **Notifications** are live only and
never stored or replayed; **commands** are stored for 7 days with a delivery
state per target quest, and the first runtime that acknowledges one takes
it. `send` carries a `requestId`, remembered for 24 hours, so a retry does
not send twice.

**Missing.** Addressing people and conversations instead of quests; a stored
conversation history that a client reads in pages and since a point; read
state per user; a thread's attachment to a document or review (an opaque
anchor the client sets); retention per group. The `requestId` rule carries
over unchanged.

### WR-5 — documents as blobs for the review exchange

**Needed.** Documents travel as **blobs** referenced from messages, as FO-8
and FO-21 plan them: content-addressed (SHA-256), uploaded once and
downloaded by the recipients, with a size limit per file and a quota per
group, and a lifetime: default 7 days, at most 30, set per message. A review
round keeps its blobs until it is merged or the maximum is reached; each
returned review copy is a new blob. Webwork sends a section, an item or a
document as a `.webwork.zip` bundle; it must learn the limit before it sends,
and it must be able to say that a round is merged so its blobs may go.

**Exists.** Nothing: a message payload is inline JSON of at most 1 MiB, and
the service stores no files. tac is meant not to become a file server.

**Missing.** Blob upload and download, the hash check, the limits and their
discovery, the lifetime with its per-message setting and the round's
extension and release, and the expiry that removes a blob.

### WR-6 — a Dart client that needs no AI runtime

**Needed.** A Dart client of tac that Webwork uses directly on the desktop,
in the browser (Flutter web) and on the phone, where no AI runtime runs: the
handshake with the user's identification, the stream with reconnect, user
messages, blobs. It must run on `dart:io` and in the browser (where a
WebSocket cannot set headers; tac's key-as-subprotocol rule covers that).

**Exists.** Only the TypeScript `TacClient` in `tom_tac_service`. The Dart
side has `tom_vscode_scripting_api`, which knows no TAC; the planned Dart API
package `tom_ai_runtime_client` (FO-11) is the runtime's client, and FO-19
puts TAC clients for other languages into the API packages.

**Missing.** The Dart TAC client itself, its package and its tests against a
running service.

### WR-7 — the runtime's runs, queues, sessions and trail for Webwork's bottom panel

**Needed.** Webwork's AI tab in the bottom panel is built from the runtime:

- Webwork's own runtime instance without a quest (`webwork-app`), reached
  through the runtime's Dart client (`tom_ai_runtime_client`);
- **runs** as the runtime's process runs: one run per Webwork area (fewer
  later perhaps), each a lane with its own prompt queue, all in the `default`
  session for now;
- **everything is queued**: a prompt is sent with *queue at the end*, *queue
  next*, or *send to the running prompt as an update*; there is no separate
  chat path;
- **per run, an option** whether its prompts run silently or each result is
  previewed and waits for the user's Apply or Discard;
- the **trail** as a bounded, appending Markdown view (the last so-many
  lines or kilobytes kept), also used for Webwork's Output channels;
- the **Flutter components** (`tom_ai_runtime_ui`): chat, queue and trail
  views;
- Webwork's **document tools** executed in Webwork (against its document
  model, inside its undo groups), offered to the runtime as the host's tools.

Webwork keeps its own UI state (which run tab is in front, per area) itself.
Anything more complex comes with Webforge.

**Exists.** All of it as behaviour inside the VS Code extension: processes
and process runs with their own queue lanes, sessions, the queue with
pre-prompts, follow-ups and soft interrupts, trails. The design
([quest_runtime_design.ai_runtime.md](quest_runtime_design.ai_runtime.md)) and
the feature overview plan the runtime package, its server and protocol
(§ 3.2), the host interface with its tools, the Dart client (§ 3.5,
`ww_e_runtimeapi-*`) and the Flutter components.

**Missing.** Everything as a runtime outside VS Code: the package and the
split (`ww_b_workbench-*`), the server and protocol (`ww_d_workbench-*`), the
Dart client, the Flutter components (not yet in a todo group), host tools
offered by a Flutter host, and the per-run preview option and the three
queueing choices as protocol operations.

## What Webwork does not need

Leases and claims, units, endpoints, the GitHub backend, migration between
backends, Telegram, and messages between runtimes are not needed for Webwork's
messaging. Webforge's webwork runtime registering in an agent group
(webwork's `qavs_collab_b-1`) is a separate matter that stays as filed.

## Where this goes next

- The todo `webworkreq1_akrn-webwork-requirement` takes this document into
  the ai_runtime specification.
- The todos `tac_webwork-1` … `tac_webwork-6` (at the end of
  [todos.ai_runtime.todo.yaml](todos.ai_runtime.todo.yaml)) are the tac
  features as the current implementation suggests them: identification,
  the team server, user messages, blobs, the Dart client, and the end-to-end
  check with Webwork. The specification may replan them.
- Webwork's wave 1b2 todos name these todos in their `blocked_by` when they
  are filed.
