# Round instructions — Phase 1, question round 3 (terminology pass)

For every todo `p1s1r3-*`. Document: `../project_idea.ai_runtime.md` (the Project Idea).
Binding terminology: `_ai/quests/ai_runtime/ai_runtime_terminology.md` § 2 (all of 2.1–2.6) —
**read it completely before changing anything.** Where this file and § 2 differ, § 2 holds.

## What the pass does

Read your part completely, sentence by sentence, and make every sentence use the agreed terms in
their agreed sense. A search for the words below finds candidates; it does not replace the reading:
a sentence can use only allowed words and still describe the old concept (a "group of agents that
coordinate", a "lock on a unit").

| Agreed term | Replaces / rule |
| --- | --- |
| **team runtimes** | "agent group", "tac group", "group" as the coordination scope |
| **account** | "customer" |
| **claim** (the attempt) / **lease** (the right) | "lock", "grant" as a noun, "request" as a noun for a claim; "to grant a lease" as a verb stays |
| **exclusive lease / shared lease** | "write lock", "read lock", "advisory" |
| **strict mode / worktree mode** of a repository | "locked repository", "branch mode" (change-branch mode is a third, named so) |
| **resource**, named `<owner>/<repository>[#<pattern>]` | "unit", "touch set", "declared resource" |
| **execution** (work on one item) vs **run** (a queue, long-lived) | "run" used for one item's work |
| the **runtime** holds a lease for an item of a run | "session holds", "agent holds"; "session" is not used in coordination |
| **agent** = the model acting in a session, or a sub-agent | tac never deals with agents: "agents coordinate" becomes "runtimes coordinate" |
| **person** = any human; **user** = a person using an application | use "user" where the sentence means someone using a host or the supervision application |
| **client** always with its kind (runtime client, tac client); **client SDK** (runtime client SDK, tac client SDK) | bare "client", "client package", "client library", "API package" |
| **server** always with its kind (tac server, runtime host server, MCP server) | bare "server"; a runtime is a "runtime process", never a server |
| **application / host / runtime host server** | "app" and "host" used loosely |
| **owner** always qualified (quest owner, team owner, repository owner, product owner) | bare "owner" |
| **visible**, **todo offer**, **personal team** | as § 2 defines them |

## What stays as it is

- Every id (section ids, CR./CP./CA./CI./CW./N-/D-/X-/R-/… item ids) and every reference chain.
- The meaning of every item. This is a wording pass: no requirement is added, dropped or changed.
  Where making a sentence consistent would change what it demands, do not change it — ask (below).
- Quotations: a source's title, a quoted answer of the product owner, the name of a file, package,
  tool, setting or protocol field (`tom_tac_service`, a `lock` field of `tac/1.0`, `session` in
  `tac/1.0`'s API) keep their words; where an old word is a protocol or code name, say so once
  ("the `lock` record of `tac/1.0`") instead of renaming it.
- Decisions and contradictions (`DEC`, `CON`) that record what was once said: their history
  wording may name the old word in quotes when the entry is about that word (D-60, X-5).
- `GLO` is changed only by `p1s1r3-7`.

## Known leftover

`NFR > NFR-TOPO` still says "On the always-on machine only the tac server runs in the first
version", which contradicts T8, CR.46 and D-51 / D-52 (the runtime host server runs there in the
first version). `p1s1r3-5` corrects it.

## How to write the changes

Edit the Markdown file directly (it is a plain Markdown document, not a SOM document). Mark every
change with the inline review marks so the product owner sees it in the MD Browser:
`{~~old~>new~~}`, `{++added++}`, `{--removed--}`; a remark as `{>>…<<}` only where the reason is
not obvious. Do not rewrap paragraphs you did not change. Never break a reference chain
(`A > B > C`) across lines.

Do not commit: the round's closing item commits. Use `ztmp/` (never `/tmp`) for scratch files,
named `ai_runtime_261120_<todo-id>_<what>`, and delete them when done.

## Questions

Ask only where the terminology leaves a real choice — two agreed terms fit and the choice changes
what the text says, a sentence cannot be made consistent without changing its meaning, or the
document uses a concept § 2 has no term for. Do not ask what § 2 already decides.

Append each question to `new_questions.md` under its section, with the next free id from PQ-24 on,
in this form. **Each question must be understandable on its own**, by someone who has not read the
rest of the document:

```markdown
> **❓ PQ-24 (2026-11-20T15:10+01:00) — <topic in a few words>:** <the question, one sentence>
>
> **Context:** <the passage quoted in full with its item id and section chain; what each term in
> it means, in a sentence each; what the surrounding items say that matters>
>
> **Why I ask:** <what is unclear or inconsistent, what depends on the answer — which items would
> read differently, what a reader could get wrong>
>
> - (a) <option, as a full sentence, with what the text would then say and its consequence>
> - **(b)** <the recommended option, bold>
> - (c) <…>
>
> *Recommendation:* (b) — <why>
>
> *Assumption until answered:* <what the text says meanwhile>
>
> **Answer:**
```

Exactly one option is bold, and it is the one the recommendation names.

## At the end of your todo

Append to `changes.md` (create it if missing) a section for your part: the number of changes, the
kinds (which words became which), every place where you kept an old word on purpose and why, and
the ids of the questions you raised. Then set the todo to completed.
