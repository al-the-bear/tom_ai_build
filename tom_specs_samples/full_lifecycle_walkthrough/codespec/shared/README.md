# `<app>_codespec_shared`

Empty in this walkthrough, and legitimately so.

The shared project holds what the client and the server must agree on: the
operation catalogue and its DTOs, the CE-ER result envelope, domain enums,
message keys, error codes, validation declarations. Every one of those derives
from something this walkthrough's specification does not write — it carries an
information model and one functional requirement.

The one shared type an information model can produce on its own is the CE-API
entity wire DTO, and it does not exist here either: one DTO exists per entity
that a server operation member is typed by, and no operation is specified
(`codespecs_derivation_contract.md` §3.2.11 point 1).
