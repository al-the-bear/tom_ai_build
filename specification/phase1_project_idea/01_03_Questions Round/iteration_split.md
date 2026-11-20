# Iteration split — Phase 1, question round 3

The Project Idea has 2,487 lines. The round is one terminology pass over all of it, cut by section
so that one prompt reads its part completely. Rules of the pass: `round_instructions.md`.

| Todo | Part (section ids) | Lines (at planning) | Why its own part |
| --- | --- | --- | --- |
| `p1s1r3-1` | `ABOUT`, `SRC`, `VIS`, `USR`, `SCO`, `LAND` (not `GLO`) | 1–205, 312–457 | the framing text: person / user, owner, client and server without a kind |
| `p1s1r3-2` | `RT` | 458–991 | the runtime: run / execution / session, lock, request |
| `p1s1r3-3` | `CLI` | 992–1203 | client SDKs, supervision application: client and server kinds |
| `p1s1r3-4` | `TAC` | 1204–1729 | the densest part: claim / lease, team runtimes, visibility, account, resources |
| `p1s1r3-5` | `PAR`, `NFR` | 1730–2183 | strict and worktree mode, exclusive and shared lease; topologies and flows |
| `p1s1r3-6` | `DEC`, `CON`, `RISK`, `DEL` | 2184–2487 | decisions, contradictions and risks restate the items above in short form |
| `p1s1r3-7` | whole document, `GLO` included | — | cross-check: the glossary against the text, a word-by-word scan, the new questions inserted |

Todos 1–6 each change only their part and append their questions to `new_questions.md`; todo 7
reads `GLO`, scans the whole text for the words that are not used, inserts the questions and writes
`changes.md`.
