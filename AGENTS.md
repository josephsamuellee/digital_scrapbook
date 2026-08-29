# Coding Agent Instructions

These instructions apply to AI coding agents and are also useful as a
maintenance checklist for human engineers.

The project is intentionally small. Preserve that property.

## 1. First Principle

Implement the smallest clear change that satisfies the documented
product behavior and acceptance criteria.

Do not invent product behavior, infrastructure, abstractions, or
dependencies merely because they are common in larger systems.

## 2. Before Changing Code

For every non-trivial task:

1.  Read `README.md`.
2.  Read the specific request.
3.  Inspect the existing implementation before proposing structural
    changes.
4.  Read the relevant documents under `docs/`.
5.  Search `docs/decisions/` for prior decisions related to the area.
6.  Identify applicable acceptance-criteria IDs.
7.  Identify existing tests covering the behavior.

Do not assume conversation history is available or authoritative.

## 3. Documentation Authority

Use documents according to their intended responsibility:

``` text
product_spec.md
    ↓ product scope

ux_information_architecture.md
    ↓ user flows / destinations

wireframes.md
    ↓ layout / interaction intent

architecture.md
    ↓ system and persistence invariants

feature_specifications.md
    ↓ feature behavior

acceptance_criteria.md
    ↓ objectively testable completion conditions

formats/
    ↓ durable file/data contracts

decisions/
    ↓ reasons behind significant architectural choices
```

If documents conflict, do not silently choose whichever is easiest to
implement.

Determine whether one is clearly newer/more specific. If the conflict
changes behavior or architecture and cannot be resolved confidently,
surface it.

## 4. Preserve Core Architectural Invariants

Unless an explicit approved change updates the architecture:

-   Markdown remains the durable source of truth for Memory content.
-   SQLite remains the efficient application index/representation.
-   Stable Memory IDs never change.
-   Memory directories are not automatically renamed after creation.
-   Original image uploads are preserved.
-   Existing files are never silently overwritten on filename collision.
-   Image transformation occurs at content-change/upload time, not
    normal GET time.
-   TIMELINE/PRESENT/EDIT GET requests do not generate image
    derivatives.
-   Rails remains server-rendered first.
-   JavaScript is added only for interactions that need it.
-   Direct trusted-LAN use remains supported.
-   Core behavior must not depend on Cloudflare-only headers.
-   Application data remains isolated from other Raspberry Pi
    applications.
-   Database schema evolution uses Rails migrations.

## 5. Keep the System Small

Do not introduce the following without a concrete documented
requirement:

-   React or another SPA framework;
-   Redis;
-   Sidekiq;
-   background-job infrastructure;
-   external SQL/database service;
-   external object storage;
-   external search service;
-   analytics/telemetry platform;
-   application-level user/account system;
-   container orchestration;
-   microservices.

The expected dataset is small. Optimize for correctness, portability,
understandable code, and low maintenance rather than hypothetical scale.

## 6. Dependency Policy

Before adding a dependency:

1.  check Ruby standard library;
2.  check Rails;
3.  check current gems/packages;
4.  check existing Raspberry Pi system tools;
5.  consider a small local implementation.

The production Pi already provides shell-accessible:

``` text
magick
heif-convert
```

Either or both are acceptable for MVP image processing if they satisfy
acceptance criteria.

Do not add another heavy image-processing subsystem solely to prefer a
different tool.

When adding a dependency:

-   explain why existing capabilities are insufficient;
-   keep the dependency narrowly scoped;
-   add/update setup documentation;
-   add an ADR if the dependency establishes a durable architectural
    constraint.

## 7. Data Safety

Treat user-authored Memories and photographs as durable personal data.

Never:

-   delete production data as a shortcut;
-   recreate the production database as a schema-migration strategy;
-   overwrite an original photograph;
-   silently merge ambiguous Memories;
-   regenerate missing authoritative Markdown from stale SQLite without
    an explicit recovery specification;
-   overwrite externally changed Markdown with stale browser EDIT state.

For file writes, preserve the documented safe-write ordering.

## 8. Markdown Format

Before changing Markdown parsing or serialization:

1.  read the current format specification under `docs/formats/`;
2.  inspect parser/serializer tests;
3.  add tests for new/changed syntax;
4.  preserve backward compatibility unless a migration is explicitly
    designed.

Prefer deterministic parsing and serialization.

Maintain round-trip semantic tests:

``` text
parse -> representation -> serialize -> parse
```

The final semantic Memory should be equivalent to the initial one even
if formatting is normalized.

## 9. Reconciliation

Reconciliation is a high-risk data-integrity boundary.

Rules include:

-   valid Markdown wins over duplicated SQLite metadata;
-   stable ID is the strongest identity key;
-   source filename/path association is secondary;
-   title similarity alone is not identity;
-   ambiguity produces an explicit/manual-resolution condition;
-   one malformed Memory should not break unrelated Memories;
-   stale active browser EDIT state must not overwrite an external
    change.

Changes to reconciliation require focused automated tests.

## 10. Image Processing

Observable behavior matters more than which installed command performs
the work.

Maintain these invariants:

-   supported originals are preserved;
-   HEIC original remains preserved;
-   normalized JPEG is generated when required;
-   presentation JPEG target quality is approximately 90;
-   presentation long edge is at most 2560 px;
-   smaller images are not unnecessarily upscaled;
-   orientation/aspect ratio are preserved;
-   thumbnails are generated at upload/change time;
-   processing failure does not insert broken Markdown;
-   browser-visible errors are useful but sanitized;
-   detailed diagnostics remain in server logs.

## 11. Testing Expectations

Before declaring a task complete:

1.  run the narrowest relevant tests while developing;
2.  run all tests affected by the changed subsystem;
3.  run the full suite when practical;
4.  identify which acceptance criteria were verified;
5.  distinguish automated checks from human-only visual checks.

Do not fabricate visual acceptance results.

Criteria marked `[MANUAL]` in `docs/acceptance_criteria.md` require
human/device verification unless the task explicitly provides reliable
visual evidence.

Do not replace subjective manual checks with arbitrary screenshot/pixel
assertions.

## 12. High-Value Test Boundaries

Prefer strong tests around:

``` text
Markdown parser
Markdown serializer
round-trip semantics
Memory validation/readiness
atomic Memory persistence
SQLite reconciliation
external-edit detection
stale EDIT conflicts
image processing
filename collision behavior
Timeline date geometry
cross-year Timeline behavior
draft selection
```

Avoid over-testing framework internals.

## 13. Architecture Decision Records

Before making a meaningful architectural choice, search:

``` text
docs/decisions/
```

The purpose of ADRs is to prevent future agents from repeatedly
reconsidering settled decisions without knowing the original
constraints.

Create a new ADR when a change:

-   establishes a durable architecture choice;
-   replaces a prior architecture choice;
-   introduces an important dependency/service;
-   changes authoritative data ownership;
-   changes a portable file format;
-   creates a significant compatibility or operational constraint.

Do not create ADRs for routine refactoring, naming, CSS tuning, or local
implementation details.

### Efficient ADR format

Keep ADRs short:

``` text
# ADR-NNN: Decision title

Status: Proposed | Accepted | Superseded
Date: YYYY-MM-DD

## Context
What problem/constraint caused the decision?

## Decision
What did we choose?

## Reasons
Why is this preferable here?

## Consequences
What becomes easier, harder, or constrained?

## Supersedes / Superseded by
Optional links.
```

Prefer one clear decision per ADR.

Never rewrite an old accepted ADR to make history look cleaner. If the
decision changes, add a new ADR and mark/link the old one as superseded.

## 14. Documentation Changes

Update documentation when behavior or contracts change.

Use this mapping:

``` text
Product scope changed
    -> product_spec.md

User flow/navigation changed
    -> ux_information_architecture.md

Layout/interaction intent changed
    -> wireframes.md

System/data/deployment invariant changed
    -> architecture.md
    -> possibly ADR

Feature behavior changed
    -> feature_specifications.md

Definition of correct behavior changed
    -> acceptance_criteria.md

Markdown/data format changed
    -> formats/

Important user-visible/compatibility change
    -> CHANGELOG.md
```

Do not duplicate large blocks between documents.

## 15. Change Summaries

When completing non-trivial work, report:

-   what changed;
-   important files changed;
-   tests run and result;
-   acceptance criteria satisfied;
-   migrations/dependencies introduced;
-   documentation updated;
-   remaining manual verification;
-   known limitations or unresolved issues.

Do not claim success for tests that were not run.

## 16. Refactoring

Refactoring should preserve documented behavior unless the task
explicitly changes it.

Prefer:

-   small service objects around complex domain boundaries;
-   conventional Rails organization;
-   descriptive names;
-   direct code over speculative abstraction.

Avoid:

-   generic frameworks for one use case;
-   premature plugin systems;
-   unnecessary metaprogramming;
-   abstraction layers whose only purpose is possible future scale.

Future layout selection is expected, but implement only enough extension
points to avoid trapping the MVP---not a complete layout framework
before it is needed.

## 17. Migrations

All persistent SQLite schema changes require Rails migrations.

Never instruct a user to delete/recreate `production.sqlite3` merely to
adopt a new schema.

Migrations should be reversible where reasonably possible and safe for
existing Memories.

## 18. Production Assumptions

Expected production environment:

``` text
Raspberry Pi 4
Rails :8086
SQLite
filesystem data root
Cloudflare -> cloudflared -> Rails
trusted LAN -> Rails directly
```

Do not assume production has large compute/memory capacity.

Do not optimize prematurely, but avoid moving expensive deterministic
work into frequently executed GET paths.

## 19. Security Scope

MVP authentication is an external deployment concern.

Do not add an application account system unless product/architecture
documentation changes.

Still follow normal application safety:

-   validate inputs;
-   prevent arbitrary filesystem traversal;
-   expose only controlled Memory assets;
-   sanitize browser-visible command errors;
-   do not execute user-provided shell fragments;
-   use safe command invocation for image tools.

## 20. Completion Checklist

Before finishing a non-trivial task:

``` text
[ ] Read relevant docs
[ ] Checked prior ADRs
[ ] Inspected existing code
[ ] Identified acceptance criteria
[ ] Implemented smallest coherent change
[ ] Added/updated tests
[ ] Ran relevant tests
[ ] Ran full suite when practical
[ ] Preserved data-safety invariants
[ ] Used Rails migration for schema changes
[ ] Updated docs if contracts changed
[ ] Added ADR only if decision is durable/significant
[ ] Updated CHANGELOG if appropriate
[ ] Reported manual verification still required
```
