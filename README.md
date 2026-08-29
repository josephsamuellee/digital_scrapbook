# RPi4 Digital Scrapbook

A private, lightweight Rails application for authoring, retrieving, and
presenting short visual Memories over time.

The application runs on a Raspberry Pi 4, uses SQLite plus a portable
filesystem data root, and is designed to remain understandable and
maintainable by both future software engineers and AI coding agents.

## Product Summary

The core object is a **Memory**: a short visual scrapbook presentation
such as a trip, holiday, wedding, or other period worth preserving.

Primary user-facing destinations:

1.  **TIMELINE** --- browse Memories chronologically.
2.  **PRESENT** --- present one Memory page-by-page.
3.  **EDIT** --- create or modify a Memory.

MVP is private. External authentication is handled outside Rails by
Cloudflare. There is no application-level user/account system.

## Start Here

Before making a non-trivial change, read the project documentation
relevant to the work.

Recommended order for initial onboarding:

1.  `README.md`
2.  `AGENTS.md`
3.  `docs/product_spec.md`
4.  `docs/ux_information_architecture.md`
5.  `docs/wireframes.md`
6.  `docs/architecture.md`
7.  `docs/feature_specifications.md`
8.  `docs/acceptance_criteria.md`
9.  relevant files under `docs/formats/`
10. relevant Architecture Decision Records under `docs/decisions/`

Do not treat old implementation behavior as more authoritative than an
explicit current specification without investigating the discrepancy.

## Repository Structure

Target repository structure:

``` text
.
├── README.md
├── AGENTS.md
├── CHANGELOG.md
│
├── app/
│   ├── controllers/
│   ├── models/
│   ├── services/
│   ├── views/
│   ├── helpers/
│   └── javascript/
│
├── bin/
│   ├── setup
│   ├── dev
│   └── test
│
├── config/
├── db/
│   └── migrate/
│
├── docs/
│   ├── product_spec.md
│   ├── ux_information_architecture.md
│   ├── wireframes.md
│   ├── architecture.md
│   ├── feature_specifications.md
│   ├── acceptance_criteria.md
│   │
│   ├── formats/
│   │   └── memory_markdown_v1.md
│   │
│   └── decisions/
│       ├── README.md
│       ├── 001-....md
│       └── ...
│
├── test/
│   ├── models/
│   ├── services/
│   ├── controllers/
│   ├── system/
│   └── fixtures/
│       └── files/
│
└── ...
```

Not every target file needs to exist before its subject is implemented.
The structure establishes where durable knowledge belongs.

## Documentation Responsibilities

Each document has a different purpose.

  -----------------------------------------------------------------------
  Document                            Responsibility
  ----------------------------------- -----------------------------------
  `product_spec.md`                   What the product is and is not

  `ux_information_architecture.md`    User destinations, flows, and
                                      information organization

  `wireframes.md`                     Layout and interaction intent

  `architecture.md`                   System boundaries, persistence,
                                      deployment, and technical
                                      invariants

  `feature_specifications.md`         Exact behavior of independently
                                      understandable features

  `acceptance_criteria.md`            Objective definition of correct
                                      implementation

  `formats/`                          Durable file/data format contracts

  `decisions/`                        Why significant technical choices
                                      were made

  `CHANGELOG.md`                      Important user-visible and
                                      compatibility changes

  `AGENTS.md`                         Operating rules for coding agents
                                      and maintainers
  -----------------------------------------------------------------------

Avoid copying the same specification into several documents. Link to the
authoritative document instead.

## Architecture at a Glance

``` text
Internet
   ↓
Cloudflare (HTTPS + external authentication)
   ↓
cloudflared
   ↓
Rails :8086 on Raspberry Pi 4
   ↓
SQLite + controlled filesystem data root

Trusted LAN:
http://192.168.12.111:8086
```

Core principles:

-   server-rendered Rails first;
-   JavaScript only where interaction requires it;
-   Markdown is the durable source of truth for Memory content;
-   SQLite is the efficient application index/representation;
-   original photographs are preserved;
-   image derivatives are generated at content-change time, not on GET;
-   stable Memory IDs do not change;
-   Memory directories are not automatically renamed after creation;
-   no Redis, Sidekiq, SPA framework, external object store, external
    search service, or application analytics unless a later documented
    requirement justifies them.

## Memory Storage

A Memory is self-contained under the configured data root.

Example:

``` text
<data_root>/
├── production.sqlite3
└── memories/
    └── 042-5831047291/
        ├── memory.md
        ├── IMG_1234.jpg
        ├── IMG_1234_present.jpg
        ├── IMG_1234_thumb.jpg
        ├── IMG_5678.HEIC
        ├── IMG_5678.jpg
        ├── IMG_5678_present.jpg
        └── IMG_5678_thumb.jpg
```

The numeric prefix is the stable Memory ID. The random suffix permits
directory allocation before the Memory has a title.

The directory name is not the Memory title and should not be
automatically renamed when the title changes.

The absolute data root is deployment configuration and must not be
scattered as a hard-coded path throughout application logic.

## Image Processing

The production Raspberry Pi already exposes shell-accessible:

``` text
magick
heif-convert
```

Either or both may be used for MVP image processing.

Choose the simplest maintainable implementation that satisfies the image
acceptance criteria. Do not add another heavy image-processing subsystem
merely to prefer one tool over the already-installed alternatives.

Important invariants:

-   preserve originals;
-   never overwrite filename collisions;
-   preserve image aspect ratio/orientation;
-   normalized/presentation JPEG quality target is approximately 90;
-   PRESENT long edge is at most 2560 px;
-   do not upscale unnecessarily;
-   generate thumbnails during upload;
-   do not transform images during normal TIMELINE/PRESENT/EDIT GET
    requests.

## Development

Runtime pin (matches the production Raspberry Pi):

-   Ruby `4.0.5`
-   Rails `7.2.3`

See `docs/decisions/001-ruby-rails-versions.md`.

Expected conventional commands:

``` bash
bin/setup
bin/dev
bin/test
```

`bin/dev` starts Puma on port `8086`. Override with `PORT`.

Application data root (SQLite plus `memories/`):

``` bash
export SCRAPBOOK_DATA_ROOT=/absolute/path/to/data
```

If unset, development and test use `storage/scrapbook` inside the
repository. Do not hard-code the production Pi path in application
code.

`bin/setup` installs gems, creates the data root, and prepares SQLite.

TIMELINE (`GET /`) lists PRESENT-ready Memories on reverse-chronological
year axes using leap-year-aware proportional dates. Labels use the
pre-generated `_thumb.jpg` key photo plus the title. Incomplete drafts
stay off the Timeline. No `magick` or `heif-convert` runs on Timeline GET.

Timeline, PRESENT, and EDIT GET requests reconcile `memory.md` files under
the data root into SQLite by stable YAML ID: external metadata edits win,
moved directories update `source_path`, and orphan folders can be
imported. Ambiguous identity is logged and not merged by title.

PRESENT is `GET /memories/:id`. View Presentation persists the editor, then
opens that route when the Memory is ready; otherwise EDIT lists the
blocking requirements. PRESENT uses pre-generated `_present.jpg`
derivatives and does not run `magick` or `heif-convert` on GET.

EDIT image upload uses the production Pi's existing `magick` and
`heif-convert` commands. JPEG/JPG uploads preserve the original and
write `_present.jpg` and `_thumb.jpg` at upload time. HEIC uploads keep
the original and write a normalized JPEG master plus those
derivatives. Markdown inserted at the editor cursor references the JPEG
(not the HEIC).

Local JPEG image tests require `magick` on `PATH`. HEIC examples skip
unless `heif-convert` is installed. On macOS:

``` bash
brew install imagemagick
# optional, for HEIC tests and local HEIC uploads:
brew install libheif
```

Keep these commands current as the application develops.

## Production

Expected deployment characteristics:

-   Raspberry Pi 4
-   Rails service on port `8086`
-   SQLite
-   filesystem Memory data root
-   `cloudflared` for external access
-   Cloudflare authentication boundary
-   direct trusted-LAN access also supported

Application behavior must not require Cloudflare-specific headers
because direct LAN use is a supported access path.

## Database Changes

Use Rails migrations for SQLite schema evolution.

Do not delete and recreate the production database as a migration
strategy.

Even though Memory content is designed to be portable/reindexable from
Markdown, future database state may not be fully reconstructable.

## Tests as Executable Specification

Tests should trace back to `docs/acceptance_criteria.md`.

Important high-risk areas deserve focused automated tests:

-   Markdown parsing;
-   Markdown serialization;
-   parse/serialize round trips;
-   reconciliation;
-   safe/atomic persistence;
-   stale-editor conflict protection;
-   image processing;
-   Timeline date geometry;
-   draft selection/readiness.

A formatting-normalized Markdown round trip may differ textually while
preserving semantic content.

## Architecture Decision Records

Significant architectural decisions belong under:

``` text
docs/decisions/
```

The purpose is not bureaucracy. It is to preserve the reasoning that a
future engineer or AI agent cannot reliably reconstruct from code alone.

Create an ADR when a decision:

-   establishes or changes a durable architectural boundary;
-   selects between meaningful competing approaches;
-   introduces an important dependency or service;
-   changes persistence/data-format behavior;
-   creates a compatibility constraint;
-   intentionally deviates from an existing project principle.

Do **not** create ADRs for routine implementation details.

ADRs should be concise. Record:

``` text
Title
Status
Date
Context
Decision
Reasons
Consequences
```

The goal is **efficient future decision retrieval**. A future agent
should be able to search `docs/decisions/`, understand why the current
design exists, and avoid repeatedly reopening settled architectural
questions.

If a decision is superseded, preserve the old ADR and link it to the
replacement rather than rewriting history.

## Maintaining AI-Friendly Project Context

The repository should remain navigable without relying on conversation
history.

When a significant decision is made:

1.  put the behavioral contract in the appropriate specification;
2.  put architectural reasoning in an ADR when warranted;
3.  update acceptance criteria if observable behavior changes;
4.  add/update tests;
5.  update CHANGELOG when the change is user-visible or
    compatibility-relevant.

Do not rely on an AI agent to remember prior conversations.

Prefer small, authoritative documents with clear ownership over large
duplicated design summaries.

## Dependency Discipline

Before adding a gem, npm package, service, daemon, or system dependency:

1.  check Ruby/Rails standard capabilities;
2.  check existing project dependencies;
3.  check existing system tools;
4.  consider a small local implementation;
5.  add a dependency only when it materially simplifies or improves
    correctness/maintenance.

A new dependency should be explained in the change summary. Significant
dependencies may warrant an ADR.

## Change Discipline

Before completing a non-trivial change:

1.  identify the applicable feature specification;
2.  identify the applicable acceptance criteria;
3.  implement the smallest coherent change;
4.  run relevant tests;
5.  run the full test suite when practical;
6.  verify architectural invariants;
7.  update documentation when a contract changed;
8.  report unresolved criteria explicitly.

Do not silently change product behavior merely because a different
implementation seems convenient.

## MVP Non-Goals

MVP is not:

-   social media;
-   a public website;
-   a photo backup service;
-   collaborative editing;
-   a sharing platform;
-   a map/GPS product;
-   a travel planner;
-   a PowerPoint clone;
-   a photo-gallery/file-manager-first interface;
-   a standalone mobile application.

See `docs/product_spec.md` for the authoritative product scope.
