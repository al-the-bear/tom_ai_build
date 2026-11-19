# New questions — Phase 1, question round 2

The three questions this round puts to the product owner, as they stand in the Project Idea.

## `USR > USR-TEAM`

> **❓ PQ-22 (2026-11-19T18:45+01:00) — Your entry in the review team:** how are you written in the review team of the specification documents?
>
> **Context.** You answered that you are the owner and the only reviewer: "owner and reviewer am I, alexis". The Solution Blueprint records its review team as a list of members, each with a member id (lowercase letters, digits and `_`), a display name and a role; the owner is marked. The member id is what review marks and answers are signed with; the display name is what the documents show. From your answer I took the member id `alexis` and the role "product owner". The display name was not given.
>
> **Why I ask.** The first step of the next phase writes this entry into the Blueprint, and review copies are named after the member id.
>
> - **(a)** Member id `alexis`, display name "Alexis", role "Product owner". No e-mail address is stored.
> - (b) The same, with another display name or an e-mail address — write them in the answer.
>
> *Recommendation:* (a).
>
> **Answer:**

## `RT > RT-PROTO`

> **❓ PQ-21 (2026-11-19T18:45+01:00) — Three shapes of the runtime's protocol:** do you confirm how the runtime tells a host about a conversation, about a question, and when it lets go of a run?
>
> **Context.** This asks the earlier question again, in other words. It is **not** about the ways an agent asks you something. Those stay exactly as they are: a review outside a turn, the tool that asks single questions, and questions inside a document. You named them in your answer, and nothing is missing there.
>
> The question is about the **wire between a runtime and a host**. Today the engine and the views are one program (the VS Code extension), so the engine just calls the view. Once the runtime is a program of its own, a host (Webforge, Webwork, the supervision application) is a separate program that only receives messages. Three things about those messages are so far only proposed:
>
> 1. **How a conversation arrives.** Today the engine writes a flat trail: one entry after another (text, a tool call, a result). Proposed: the runtime sends a conversation in three levels. A *thread* is a session. A *turn* is one prompt with everything that answers it. An *item* is one piece of a turn: a text, a piece of reasoning, a tool call, a question, a result. Each item is announced when it starts, streamed in pieces, and closed. Example of what a host receives for one prompt: `turn started` → `item started (reasoning)` … `item completed` → `item started (tool call: read file)` → `item completed (result)` → `item started (text)` → `delta "The file…"` → `delta " holds…"` → `item completed` → `turn completed (usage)`. A host can then draw a tool card or a reasoning block without guessing where it begins and ends, and can steer or interrupt a turn by its id.
> 2. **How a question arrives.** Today each way of asking has its own code path to its own panel. Proposed: whatever the way of asking, the runtime sends the host **one record** with the same fields: an id; a kind (question, pick from a list, a document to answer in, approval of a tool call, approval of a plan, a decision, a gate result); the allowed responses; an optional form of the response; a default, if one was declared; a deadline. Example: your gate decision arrives as `{id, kind: gate, responses: [passed, failed], deadline: none}`, and a tool approval as `{id, kind: tool approval, responses: [allow, deny], default: deny}`. A host needs one inbox and one way to answer instead of seven, and a question can be passed on to another device or person because it is a record.
> 3. **When a run is let go.** A runtime holds every run of its quest in memory. Proposed: a run that nobody watches (no host is subscribed to it) and that has nothing queued is unloaded, and loaded again from its files when someone opens it or queues something. Example: Webwork has one run per area; the runs of areas you have not opened today cost nothing.
>
> **Why I ask.** The protocol specification is written from these shapes, and every client library in every language and every UI component is built on them. Changing them later changes all of those.
>
> - **(a)** **All three as described.**
> - (b) **The question record and the unloading, but the conversation stays a flat trail** as today. Less to change in the engine; every host then has to work out by itself where a turn and a tool call begin and end, in every language.
> - (c) **Different** — say which of the three, and how.
>
> *Recommendation:* (a) — the three levels are what the other agent protocols have settled on, so the UI components and an adapter to those protocols get simpler.
>
> **Answer:**

## `TAC > TAC-PEOPLE > TAC-GROUPS`

> **❓ PQ-20 (2026-11-19T18:45+01:00) — Who an agent group belongs to:** on a server, who creates an agent group, and which runtimes may join it?
>
> **Context.** The section above this question explains what an agent group is: the set of runtimes that share repositories and therefore share one pool of leases, across quests and machines. A **team** is people. A **customer** is whoever a server serves (an organisation, or you); the server keeps access keys and quotas per customer. You decided that a team and an agent group are two different things, that "a team has owners; the first is whoever created the team", and you wrote about this question: "I'd say team member can create or delete their own agent groups, but this depends on our definitions."
>
> Three things are not said anywhere: whether an agent group belongs to a customer, to a team or to a person; who creates the first customer on a new server; and which runtimes may join a group.
>
> **Why I ask.** The Solution Blueprint has an information model (which records exist and how they point to each other) and a security model (who may call which operation). Both need this. It also decides what the first day on a new server looks like.
>
> - **(a)** **A group belongs to the customer and is opened to teams; a team's owner creates it.** Whoever installs the server creates the first customer and its first access key from the server's command line. With that key a person creates a team and is its first owner. A team's owner creates an agent group; it belongs to the customer. A team lists the agent groups its members' runtimes may join, and a group may be listed by several teams of the same customer, so two teams that share repositories share the leases on them. A runtime joins a group with its person's token of a team that lists the group. For you: one customer, one team with you in it, one agent group for all your machines.
> - (b) **As (a), and every member may create agent groups**, as you suggested: a member creates a group, it is listed in that member's team, and the member who created it (or an owner) may delete it. More freedom; a team can end up with several groups over the same repositories, whose runtimes then do not see each other's leases — the one thing a group is for.
> - (c) **A group belongs to exactly one team.** A team's owner creates its groups, and only that team's members' runtimes join them. Simpler to explain. Two teams working on the same repositories cannot share leases.
> - (d) **Groups stay as today:** no owner, no creation; any runtime with the customer's key that names a group is in it. Teams only concern messaging and remote control. Nothing to administer; nothing keeps a runtime out of a group.
>
> *Recommendation:* (a) — a group only works when everyone who writes to a repository is in the same one, so creating one should be a deliberate act of an owner, and it must be possible for two teams to share one.
>
> **Answer:**
