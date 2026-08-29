# Architecture

## 1. Purpose

This document defines the technical architecture for the MVP described by:

- `product_spec.md`
- `ux_information_architecture.md`
- `wireframes.md`

It is intended to be an AI-agent-ready architectural contract. It defines system boundaries, sources of truth, persistence, filesystem organization, image processing, Markdown parsing, reconciliation, request paths, deployment assumptions, and implementation constraints.

This is a small, low-volume, private, self-hosted application running on a Raspberry Pi 4 alongside other services. Prefer the simplest architecture that preserves portability, maintainability, and predictable behavior.

Do not introduce additional frameworks, services, persistence systems, JavaScript application stacks, job queues, or infrastructure unless a later specification explicitly requires them.

---

## 2. Architectural Principles

### 2.1 Optimize work at content-change time

Expensive work should happen when content changes, not when it is presented.

In particular:

- image normalization and resizing happen synchronously during upload;
- PRESENT serves pre-generated derivatives;
- image transformation must never occur during GET/PRESENT requests;
- Timeline reads should use indexed SQLite metadata rather than repeatedly parsing every Markdown file.

### 2.2 Markdown is the durable source of truth

Each Memory's Markdown file is the durable, portable source of truth for:

- Memory identity;
- portable Memory metadata;
- authored Memory Page content;
- image references;
- page order.

SQLite is an application index/cache of metadata used for efficient application behavior.

If the SQLite database is lost, the Memory directories and Markdown files must contain enough information to reconstruct the application index.

### 2.3 Files remain independently usable

The application must not become the only usable representation of a Memory.

A Memory directory should remain understandable using ordinary filesystem and Markdown tools.

Original uploaded files must remain ordinary files.

### 2.4 Stable identity is independent of presentation names

A Memory has a stable numeric internal identity.

Titles, slugs, filenames, and directory labels may be human-readable but are not the Memory's identity.

Renaming a Memory must not automatically rename its directory.

### 2.5 Server-rendered Rails first

Use Rails server-rendered HTML as the default application model.

Use JavaScript only for interactions that require it, including:

- PRESENT swipe navigation;
- PRESENT keyboard navigation;
- autosave;
- EDIT page-strip interactions;
- page reordering controls where necessary;
- inserting uploaded image references at the editor cursor;
- small responsive/interactivity helpers.

Do not introduce React, another SPA framework, or a separate frontend application for MVP.

### 2.6 Minimize infrastructure

MVP does not require:

- Redis;
- Sidekiq;
- background job infrastructure;
- external object storage;
- external search;
- external telemetry;
- analytics;
- a separate image-processing service;
- application-level authentication.

---

## 3. System Context

Expected deployment:

```text
                         Internet
                            |
                            v
                       Cloudflare
                  authentication / HTTPS
                            |
                            v
                       cloudflared
                            |
                            v
+--------------------------------------------------+
| Raspberry Pi 4                                   |
|                                                  |
| Rails application :8086                          |
|                                                  |
|   +----------------+     +--------------------+  |
|   | SQLite         |     | controlled data    |  |
|   | application    |     | root               |  |
|   | index/state    |     |                    |  |
|   +----------------+     | memories/          |  |
|                          |   001-.../         |  |
|                          |   002-.../         |  |
|                          +--------------------+  |
+--------------------------------------------------+
             ^
             |
      local network access
    192.168.12.111:8086
```

The Rails service must support both:

1. direct LAN access at `192.168.12.111:8086`; and
2. traffic forwarded through a Cloudflare Tunnel.

Cloudflare is expected to handle public HTTPS and the external authentication boundary.

Rails does not implement user accounts or application-level authentication in MVP.

Do not assume that requests will always arrive through Cloudflare; LAN access is a supported path.

---

## 4. Major Components

### 4.1 Rails application

Rails owns:

- HTTP routing;
- TIMELINE rendering;
- PRESENT rendering;
- EDIT rendering;
- Memory creation/edit operations;
- Markdown parsing and serialization;
- SQLite indexing;
- Markdown/SQLite reconciliation;
- image upload validation;
- synchronous libheif processing;
- autosave endpoints;
- error handling and logging.

### 4.2 SQLite

SQLite provides the application's fast query/index representation.

It should contain enough indexed metadata to render the Timeline and resolve Memory identities without parsing every Markdown file on every request.

SQLite is not the durable source of truth for portable Memory content.

### 4.3 Filesystem data root

A dedicated application data root stores:

- Memory directories;
- Markdown source;
- original image uploads;
- normalized images when required;
- PRESENT derivatives;
- Timeline/editor thumbnails.

This data root is independent from all other applications on the Raspberry Pi.

### 4.4 libheif

libheif performs synchronous upload-time image processing.

No image processing occurs during PRESENT requests.

---

## 5. Data Ownership and Sources of Truth

### 5.1 Markdown ownership

`memory.md` is authoritative for portable Memory metadata and authored content.

It contains YAML front matter plus Markdown body content.

### 5.2 SQLite ownership

SQLite is authoritative only for application-specific indexed/runtime state that is not intended to define the portable Memory itself.

For metadata duplicated between Markdown and SQLite, Markdown wins during reconciliation.

### 5.3 Filesystem ownership

The Memory directory is authoritative for the existence of its associated image assets.

SQLite may index/reference assets, but an asset should remain a normal file.

### 5.4 Duplication is intentional

Portable metadata is deliberately duplicated:

```text
memory.md YAML front matter
            |
            | indexed into
            v
SQLite Memory record
```

This is not two independent sources of truth.

The duplication exists so:

- Markdown remains portable;
- Timeline queries remain inexpensive;
- external/manual Markdown edits can be detected and reconciled.

---

## 6. Memory Identity

### 6.1 Stable ID

Each Memory receives a stable integer ID when first created.

Filesystem presentation uses a three-digit, zero-left-padded representation:

```text
001
002
003
...
042
...
999
```

A few hundred Memories are expected over the lifetime of the application.

The database may store the ID as an integer; zero padding is a filesystem/display convention.

### 6.2 Directory identity

A Memory directory includes the stable ID and a random 10-digit suffix so the directory can be allocated before a title exists.

Example:

```text
memories/
  042-5831047291/
```

The `042` portion is the stable identity.

The `5831047291` portion is only for unique allocation. It is not the Memory title.

See `docs/decisions/002-memory-directory-names.md`.

### 6.3 Directory names are not automatically renamed

If the Memory title later changes from:

```text
Taiwan 2026
```

to:

```text
Taiwan + Hong Kong 2026
```

the application does not automatically rename:

```text
042-5831047291/
```

This avoids unnecessary filesystem mutation and broken references.

---

## 7. Memory Filesystem Layout

Recommended structure:

```text
<data_root>/
  production.sqlite3

  memories/
    001-5831047291/
      memory.md

      IMG_1234.jpg
      IMG_1234_present.jpg
      IMG_1234_thumb.jpg

      IMG_5678.HEIC
      IMG_5678.jpg
      IMG_5678_present.jpg
      IMG_5678_thumb.jpg

    002-1928374650/
      memory.md
      ...
```

The exact absolute data-root path is deployment configuration and must not be hard-coded into domain logic.

Use a Rails/environment configuration value for the application data root.

---

## 8. Markdown Format

### 8.1 YAML front matter

Every `memory.md` begins with YAML front matter.

Conceptually:

```markdown
---
id: 42
title: Taiwan 2026
start_date: 2026-02-03
end_date: 2026-02-17
key_photo: IMG_1234.jpg
subtitle: Taiwan and Hong Kong
---

# Taiwan 2026

Taiwan and Hong Kong

## February 4

![Taipei](IMG_1234.jpg)

- Arrived in Taipei
- Dinner with family

## February 5

...
```

The exact required/optional field schema belongs in the Markdown Feature Specification.

### 8.2 H1

H1 represents Memory/title-level content.

The application should normally generate/manage the title page using structured metadata rather than requiring the user to manually maintain H1 Markdown.

### 8.3 H2

H2 (`##`) is reserved as the persistent boundary between authored Memory Pages.

The application owns H2 boundaries.

The per-page EDIT interface must not allow an H2 typed inside a page to silently create a new page.

### 8.4 One Markdown file per Memory

A Memory containing one page or twenty pages remains one `memory.md`.

Do not create one Markdown file per page for MVP.

---

## 9. SQLite Model Responsibilities

At minimum, the indexed Memory representation should support:

```text
Memory
- id
- source_filename / source_path
- title
- start_date
- end_date
- key_photo
- subtitle (if indexed/useful)
- markdown_modified_at or equivalent change fingerprint
- created_at
- updated_at
```

Exact Rails schema belongs in implementation/feature specifications.

### 9.1 Source association

SQLite must explicitly retain the Markdown source file/path associated with each Memory.

This allows reconciliation to identify:

- which SQLite record previously represented a file;
- whether a source file has changed externally;
- whether a source path has moved or become ambiguous.

### 9.2 Stable ID matching

The YAML `id` is the strongest reconciliation key.

Filename/path is also recorded and used as supporting association information.

Do not identify Memories solely by title.

---

## 10. Reconciliation

### 10.1 Goal

The application must tolerate a user editing `memory.md` outside the Rails application.

A manual filesystem edit must not require manually editing SQLite.

### 10.2 Normal application write

Normal EDIT behavior:

```text
user change
   |
   v
validate
   |
   v
write memory.md safely
   |
   v
update SQLite index
```

Both representations should normally agree immediately after an application-originated write.

### 10.3 External modification detection

The application should cheaply determine whether a Markdown source has changed since SQLite last indexed it.

Implementation may use:

- filesystem modification time;
- size;
- a lightweight content fingerprint;
- or another simple deterministic mechanism.

Because the expected dataset is only a few hundred Memories maximum, favor correctness and simplicity over complex incremental indexing infrastructure.

### 10.4 Reconciliation precedence

If Markdown and SQLite portable metadata disagree:

> Markdown wins.

The SQLite record is overwritten/reindexed from the valid Markdown metadata.

The discrepancy should be logged.

### 10.5 Matching strategy

When reconciling a Markdown file:

1. parse YAML front matter;
2. if a valid stable `id` exists, find that SQLite Memory first;
3. compare the SQLite `source_filename/source_path`;
4. if necessary, inspect records previously associated with the same source filename/path;
5. reconcile the closest unambiguous match;
6. never guess based solely on a similar title if identity is ambiguous.

If ambiguity remains, surface it for manual resolution rather than silently merging two Memories.

### 10.6 Missing SQLite record

A valid Memory directory containing `memory.md` with a stable ID should be importable/reindexable into SQLite.

The architecture should permit rebuilding the SQLite Memory index from the filesystem.

A dedicated rebuild command/UI is not necessarily required in MVP, but domain code should not make such reconstruction impossible.

### 10.7 Missing or invalid Markdown

If SQLite references a missing/unparseable Markdown source:

- log the condition;
- do not silently overwrite/create replacement Markdown from stale SQLite metadata;
- isolate the failure so other Memories remain usable;
- surface an actionable error when the affected Memory is opened.

---

## 11. Safe Markdown Writes and Recovery

### 11.1 Atomic file replacement

Do not overwrite `memory.md` directly in a way that can leave a partially written file after process interruption.

Recommended write pattern:

```text
serialize complete new memory
        |
        v
write memory.md.tmp in same filesystem
        |
        v
flush/close successfully
        |
        v
atomic rename -> memory.md
        |
        v
update SQLite index
```

### 11.2 Deterministic recovery rule

If Markdown was successfully replaced but SQLite update fails:

- Markdown remains authoritative;
- the next reconciliation reindexes SQLite from Markdown.

If temporary-file writing fails:

- preserve the previous `memory.md`;
- do not update SQLite;
- report autosave/save failure.

If SQLite was updated but Markdown replacement did not complete:

- this ordering should normally be prevented by writing Markdown first;
- if encountered, reconciliation restores SQLite from the existing authoritative Markdown.

This deliberately avoids attempting a distributed transaction across SQLite and the filesystem.

---

## 12. EDIT and Autosave Architecture

### 12.1 Page-oriented UX, whole-Memory persistence

EDIT presents one Memory Page at a time, but the persistent unit remains the complete `memory.md`.

The dataset is small. Do not introduce complex partial-document persistence solely to optimize file size.

### 12.2 Autosave payload

Favor technically simple requests.

An autosave may submit the complete current Memory editing state necessary for Rails to reconstruct the complete Markdown document, including:

- structured metadata;
- ordered pages;
- current page content.

Rails validates and serializes the full `memory.md`.

Do not create a complicated collaborative/patch/operational-transform document protocol.

### 12.3 Autosave frequency

UX requires background persistence no less frequently than once per minute while unsaved changes exist.

Autosave may occur more frequently through ordinary debouncing.

Page changes/reordering should trigger persistence as needed.

### 12.4 Autosave errors

Autosave failures must be returned to the client and reflected in the EDIT save-state indicator.

Do not display `Saved` until the server has successfully persisted the authoritative Markdown write and corresponding normal indexing operation.

---

## 13. Image Upload Pipeline

### 13.1 Supported input

MVP supports:

- JPEG/JPG directly;
- HEIC via libheif conversion to JPEG.

Other formats may be rejected unless explicitly added later.

### 13.2 Original preservation

For JPEG upload:

```text
IMG_1234.jpg             original upload
IMG_1234_present.jpg     presentation derivative
IMG_1234_thumb.jpg       thumbnail derivative
```

The original JPEG remains untouched.

For HEIC upload:

```text
IMG_5678.HEIC            original upload
IMG_5678.jpg             normalized JPEG master
IMG_5678_present.jpg     presentation derivative
IMG_5678_thumb.jpg       thumbnail derivative
```

The original HEIC is preserved.

### 13.3 Normalized JPEG

HEIC conversion uses libheif and produces a JPEG master at approximately quality 90.

The normalized JPEG should preserve orientation correctly.

Do not stretch or alter image aspect ratio.

### 13.4 PRESENT derivative

Generate synchronously during upload.

Initial architectural target:

- JPEG;
- quality approximately 90;
- maximum long edge: 2560 pixels;
- preserve aspect ratio;
- never upscale an image merely to reach 2560 pixels.

This is intentionally defined in pixel dimensions, not PPI/DPI metadata.

### 13.5 Thumbnail derivative

Generate a substantially smaller derivative for Timeline and lightweight EDIT thumbnails.

The exact pixel dimensions should be tuned during UI implementation.

Requirements:

- generated once during upload;
- derived from a normalized/original source, not generated during GET;
- small enough for fast Timeline rendering;
- large enough for recognition at the wireframe-defined thumbnail size;
- preserve aspect ratio.

Do not encode an arbitrary `100 PPI` requirement; browser transfer/rendering depends primarily on pixel dimensions and compression.

### 13.6 Processing timing

Pipeline:

```text
upload
  |
  v
validate type/name
  |
  v
choose collision-safe filename
  |
  v
persist original
  |
  +-- HEIC? --> normalize JPEG
  |
  v
generate PRESENT derivative
  |
  v
generate thumbnail
  |
  v
return successful asset reference
  |
  v
insert Markdown image reference at editor cursor
```

All processing is synchronous for MVP.

Do not add Sidekiq/Redis/background jobs.

### 13.7 Processing failure

If conversion or derivative generation fails:

- preserve a successfully stored original where reasonable;
- report the failure to EDIT;
- do not insert a broken Markdown image reference as though upload succeeded;
- log enough detail to diagnose libheif failures.

---

## 14. Filename Rules

### 14.1 Preserve uploaded names

Preserve the user's original filename whenever safe and possible.

Sanitize only as required for filesystem/security correctness.

### 14.2 Never overwrite

Uploading a filename that already exists in the Memory directory must not overwrite the existing file.

Use deterministic suffixing, for example:

```text
IMG_1234.jpg
IMG_1234_2.jpg
IMG_1234_3.jpg
```

Derivative names follow the resolved collision-safe base name.

### 14.3 Semantic derivative suffixes

Use semantic derivative names:

```text
_present
_thumb
```

Do not use names such as `_300ppi` because PRESENT optimization is defined by pixel dimensions/compression, not print-density metadata.

---

## 15. Asset Serving

Images live under a controlled application data path and are exposed through stable application asset URLs.

Architectural requirements:

- no image transformation on GET;
- PRESENT references pre-generated derivatives;
- Timeline references thumbnail derivatives;
- asset URLs should remain stable if static-serving implementation changes later.

MVP may serve controlled assets through Rails if that is operationally simplest.

The architecture must permit future optimization through a reverse proxy/static file server without requiring Memory Markdown URLs/references to be rewritten.

Do not expose arbitrary Raspberry Pi filesystem paths through user-controlled URLs.

---

## 16. Timeline Read Path

Normal Timeline request:

```text
GET /
  |
  v
query SQLite Memories
  |
  +-- optionally perform cheap stale-source detection/reconciliation
  |
  v
group by affected display year(s)
  |
  v
calculate proportional date positions
  |
  v
render server-side HTML
  |
  v
browser performs lightweight responsive layout
```

Do not parse every image or generate derivatives during Timeline GET.

Because the dataset is small, reconciliation may favor simple checks over elaborate caching, but Timeline must not repeatedly perform expensive image operations.

---

## 17. PRESENT Read Path

Normal PRESENT request:

```text
GET Memory
   |
   v
resolve stable Memory identity
   |
   v
check/reconcile source if changed
   |
   v
parse memory.md server-side
   |
   v
split authored pages at application-managed H2 boundaries
   |
   v
render server-side PRESENT HTML
   |
   v
serve pre-generated image derivatives
```

Client JavaScript handles only lightweight navigation behavior such as:

- swipe;
- arrows;
- `h` / `l`;
- page switching.

No image processing occurs in this path.

---

## 18. EDIT Read/Write Path

EDIT load:

```text
resolve Memory
   |
   v
reconcile Markdown -> SQLite if necessary
   |
   v
parse YAML metadata
   |
   v
parse H2 page boundaries
   |
   v
render page-oriented editor
```

EDIT autosave:

```text
browser editing state
   |
   v
Rails validation
   |
   v
serialize complete Markdown
   |
   v
atomic Markdown replacement
   |
   v
update SQLite index
   |
   v
return Saved / error state
```

Image upload is a separate synchronous request that returns an asset reference suitable for insertion at the editor cursor.

---

## 19. URL and Routing Principles

Use stable internal identity for routing.

Conceptual routes:

```text
/                         TIMELINE

/memories/new             create/edit interface
/memories/:id             PRESENT
/memories/:id/edit        EDIT
```

Human-readable slugs may be added for aesthetics, but must not replace the stable ID as identity.

For example, this is acceptable later:

```text
/memories/042-taiwan-2026
```

provided `042` remains the resolver.

Future SHARE may use an unguessable token:

```text
/s/:secret_token
```

SHARE is not an MVP feature.

---

## 20. Authentication and Network Boundary

### 20.1 Public/external access

Cloudflare provides:

- public HTTPS termination;
- external access/authentication boundary;
- tunnel routing through `cloudflared`.

### 20.2 Local access

The application must also operate directly at:

```text
http://192.168.12.111:8086
```

on the trusted LAN.

Do not make application behavior depend on Cloudflare-specific headers unless optional and safely handled.

### 20.3 Application accounts

MVP has no:

- User model;
- login page;
- session-based account permissions;
- editor/viewer roles.

Future secret sharing must not require redesigning Memory identity.

---

## 21. Deletion

### 21.1 Memory deletion

MVP does not require a Delete Memory UI.

Proper deletion, archival, and recovery behavior must be specified before destructive Memory deletion is exposed.

### 21.2 Image deletion

MVP does not expose per-image deletion.

Unused assets may accumulate within a Memory directory.

Future maintenance tooling may identify and delete unused assets after explicit confirmation.

### 21.3 Page deletion

Page deletion is supported because pages are logical sections inside `memory.md`.

Autosave/atomic Markdown replacement provides persistence safety, but MVP does not require a version-history system.

---

## 22. Backup Boundary

The application does not implement automated backups in MVP.

Operational backups should treat the application data root as the backup boundary:

```text
<data_root>/
  production.sqlite3
  memories/
```

The most important durable archive is:

```text
memories/
  */memory.md
  */original image files
```

SQLite is useful and should be backed up, but its Memory index should be reconstructable from valid Memory directories.

Autosave is not a backup system.

---

## 23. Logging and Error Philosophy

Use conventional Rails application logging.

No external telemetry, analytics, or error-reporting service is required.

### 23.1 Autosave errors

Autosave failures must be visible in EDIT.

Do not falsely show a Saved state.

### 23.2 Image-processing errors

libheif failures should:

- be logged;
- be returned as an understandable upload error;
- avoid inserting broken Markdown references.

### 23.3 Corrupt Memory isolation

One malformed/corrupt Memory should not crash the entire Timeline or prevent unrelated Memories from being used.

Where practical:

- log the affected stable ID/path;
- skip or mark the invalid record on broad Timeline rendering;
- show an actionable error when the affected Memory is opened.

### 23.4 Reconciliation logging

External Markdown modifications and resulting SQLite reindexing should be logged at a useful but non-alarming level.

Ambiguous identity conflicts should be treated as errors requiring manual resolution rather than automatic destructive reconciliation.

---

## 24. Performance Expectations

Expected lifetime scale is only a few hundred Memories.

Typical Memory size is approximately:

- 1–20 authored pages;
- up to three images per page;
- short Markdown text;
- a manageable number of unused uploaded assets.

Optimize for:

- simple code;
- low idle resource use;
- low PRESENT CPU use;
- pre-generated images;
- inexpensive SQLite Timeline queries.

Do not optimize for millions of rows, concurrent collaborative editing, or high request volume.

---

## 25. Development and Repository Documentation

Recommended repository structure:

```text
README.md

docs/
  product_spec.md
  ux_information_architecture.md
  wireframes.md
  architecture.md

  feature_specs/
    ...

app/
config/
db/
bin/
...
```

Provide conventional project commands where appropriate:

```text
bin/setup
bin/dev
bin/test
```

`README.md` should quickly tell a new engineer or AI agent:

- what the application is;
- required Ruby/Rails/libheif dependencies;
- how to configure the data root;
- how to initialize SQLite;
- how to run locally;
- how to run tests;
- where architectural/product specifications live.

---

## 26. AI-Agent Maintenance Rules

Future coding agents should follow these rules:

1. Read `product_spec.md`, `ux_information_architecture.md`, `wireframes.md`, and `architecture.md` before making cross-cutting changes.
2. Prefer existing architectural patterns over introducing new dependencies or frameworks.
3. Do not introduce a SPA framework without an explicit architectural decision.
4. Do not introduce Redis, Sidekiq, background-job infrastructure, or external persistence merely for convenience.
5. Preserve Markdown portability.
6. Treat Markdown as authoritative for duplicated portable Memory metadata.
7. Do not perform image transformations during PRESENT/Timeline GET requests.
8. Preserve original uploaded images.
9. Do not expose arbitrary filesystem paths.
10. Preserve stable Memory IDs.
11. Do not automatically rename Memory directories when titles change.
12. Update documentation when an architectural contract changes.
13. Favor understandable code over abstraction intended for hypothetical scale.
14. Do not add destructive deletion behavior without a corresponding recovery/deletion specification.

---

## 27. Explicitly Deferred Architectural Capabilities

The architecture should permit but does not implement:

- secret SHARE URLs;
- QR-code sharing;
- server-side asset browser;
- unused-asset maintenance;
- bulk image cleanup;
- Memory deletion/recovery;
- version history;
- automated backup;
- exact PRESENT thumbnail rendering in EDIT;
- selectable presentation templates;
- drag-and-drop editing;
- static image serving through a dedicated reverse proxy;
- richer import/rebuild administration UI.

---

## 28. Architectural Decision Summary

The following decisions are authoritative for MVP unless explicitly superseded:

- Rails server-rendered application.
- Raspberry Pi 4 deployment.
- Rails listens on/supports port `8086`.
- LAN access at `192.168.12.111:8086`.
- External traffic arrives through Cloudflare/cloudflared.
- Cloudflare handles public HTTPS/authentication.
- No application-level accounts.
- Independent SQLite database and application data root.
- Markdown is the durable source of truth.
- SQLite is an indexed application representation.
- YAML front matter duplicates portable metadata into Markdown.
- Markdown wins during reconciliation.
- External Markdown changes may overwrite/reindex corresponding SQLite metadata.
- SQLite records retain source filename/path association.
- Stable numeric Memory ID is primary identity.
- Memory directories use three-digit zero-left-padded IDs plus a random 10-digit suffix.
- Memory directories are not automatically renamed when titles change.
- One `memory.md` per Memory.
- H2 boundaries define authored Memory Pages and are application-managed.
- Server parses Markdown.
- Autosave persists the complete small Memory document rather than implementing patch-based editing.
- Markdown writes use temporary-file + atomic rename behavior.
- JPEG is a native MVP image input.
- HEIC is accepted and converted through libheif while preserving the HEIC original.
- HEIC normalized JPEG uses approximately quality 90.
- Original uploads are preserved.
- PRESENT derivative uses semantic `_present` naming and maximum 2560-pixel long edge.
- Thumbnail derivative uses semantic `_thumb` naming and is pre-generated.
- Image aspect ratio is preserved.
- Filename collisions are suffixed; files are never silently overwritten.
- Image processing is synchronous on upload.
- No image processing occurs on GET.
- No Sidekiq/Redis/background-job infrastructure.
- Assets use stable controlled URLs.
- No automated application backup.
- No Memory/image deletion UI in MVP.
- Conventional Rails logging; no external telemetry.
- Corrupt Memories should be isolated where practical.
- Repository documentation is part of maintainability requirements.
