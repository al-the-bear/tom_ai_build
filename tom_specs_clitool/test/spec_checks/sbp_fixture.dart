// A minimal Solution Blueprint for the answer-import tests: a proposal put as
// a question in the document control (PR-901), one narrative question in a
// section body (BQ-901), a combined form-preamble block with
// two field questions (BQ-902, BQ-903) above the fields of a list item's form,
// a question in an id-less text section written under its member name
// (BQ-904, `strategyNarrative`), and a question in the preamble of a
// class-level form with its `…Details` text section beside it (BQ-905,
// `ROHIPO`), in the shapes of SOM_Phase2_Iteration_Split.md § 3.1.
//
// It decodes against the D00SolutionBlueprint model; it is not complete
// enough to pass the schema and instance tiers, which the tests do not run.

/// The fixture YAML text.
const String fixtureYaml = '''
# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.
version: 2
modelVersion: "1.4"
document:
  SBP D00SolutionBlueprint:
    DOCTL documentControl:
      content: |2-
        Fixture Blueprint for the answer import.

        > **❓ PR-901 — Proposal:** is the proposal of the draft accepted?
        > - (a) yes, as the text states it
        > - (b) no
        >
        > *Recommendation:* (a).
        > *Working assumption until answered:* (a).
        >
        > **Answer:**
    INSC introductionAndScope:
      SYDSC systemDescription:
        content: |2-
          Tom UAM is the identity layer of a tenant.

          > **❓ BQ-901 — User categories:** which people are described as user
          > categories of their own?
          > - (a) only the human roles
          > - (b) the human roles plus the external user, as personas
          >
          > *Recommendation:* (b) — the external user has distinct tasks.
          > *Working assumption until answered:* (b).
          >
          > **Answer:**

          _Extrapolated — see the notes._
        SYPUP systemPurpose:
          SCBND scopeBoundaries:
            SIE-INSC-LST inScopeItems:
              SIE-INSC-TEST-CLIENT:
                headline: |2-
                  Test client and test support
                content:
                  content: |2-
                    > **❓ Open questions on these fields**
                    >
                    > **❓ BQ-902 — itemDescription:** is the test client a
                    > separate application?
                    > - (a) a separate application
                    > - (b) a mode of the own client
                    >
                    > *Recommendation:* (a) — only a separate relying party
                    > exercises the provider like a tenant application.
                    > *Working assumption until answered:* (a).
                    >
                    > **Answer:**
                    >
                    > **❓ BQ-903 — category:** which category?
                    > - (a) functional
                    > - (b) non-functional
                    >
                    > *Recommendation:* (a).
                    > *Working assumption until answered:* (a).
                    >
                    > **Answer:**

                    _Extrapolated — see the notes._
                  itemDescription: |2-
                    A test client application.
                  category: |2-
                    Functional
    STKG stakeholdersAndGovernance:
      PRPO projectOrganizationProcess:
        TOENV toolingAndEnvironments:
          TOOLI tooling:
            strategyNarrative:
              content: |2-
                The project uses the framework's own tools.

                > **❓ BQ-904 — Tool choice:** may the project add a third-party
                > tool where the framework has one?
                > - (a) no
                > - (b) yes, with the product owner's consent
                >
                > *Recommendation:* (a).
                > *Working assumption until answered:* (a).
                >
                > **Answer:**
    SAAM securityAndAccessModel:
      ACCM accessControl:
        USAU authorization:
          ROHI roleHierarchy:
            ROHIPO hierarchyPolicy:
              content:
                content: |2-
                  > **❓ Open questions on these fields**
                  >
                  > **❓ BQ-905 — hierarchyModel:** may roles include roles?
                  > - (a) yes, within the tenant
                  > - (b) no
                  >
                  > *Recommendation:* (a).
                  > *Working assumption until answered:* (a).
                  >
                  > **Answer:**
                hierarchyModel: |2-
                  Roles include roles within the tenant (BQ-905).
              roleHierarchyPolicyDetails:
                content: |2-
                  Inclusion cycles are refused.
''';
