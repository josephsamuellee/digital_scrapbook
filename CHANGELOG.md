# Changelog

This file records meaningful user-visible, compatibility, data-format,
and architectural changes to RPi4 Digital Scrapbook.

It is not intended to record every commit, refactor, CSS adjustment, or
variable rename.

The project is currently in pre-MVP design/implementation.

## Unreleased

### Added

-   Bootstrapped a Rails 7.2.3 application on Ruby 4.0.5, matching the
    Raspberry Pi runtime.
-   Empty TIMELINE (`/`) with `Our Memories`, `No memories yet.`, Add
    Memory, and a Dark/Light appearance control persisted in a browser
    cookie.
-   Configurable application data root via `SCRAPBOOK_DATA_ROOT`,
    defaulting to `storage/scrapbook` in development/test.
-   Recorded ADRs for the Ruby/Rails pin and `NNN-RANDOM10DIGITS`
    Memory directory names.
-   Defined the product around portable visual **Memories** rather than
    travel-only records.
-   Defined the three MVP destinations:
    -   TIMELINE
    -   PRESENT
    -   EDIT
-   Defined dark mode as the default appearance with a persistent
    browser light/dark preference.
-   Defined proportional year Timeline behavior, including:
    -   leap-year-aware positioning;
    -   multi-day duration segments;
    -   single-day markers;
    -   cross-year Memory continuation behavior.
-   Defined landscape-first PRESENT behavior.
-   Defined MVP PRESENT layouts for:
    -   one 3:2 or 4:3 landscape image plus commentary;
    -   two portrait images plus commentary.
-   Reserved future support for selectable/previewable presentation
    layouts.
-   Defined page-oriented Markdown editing with application-owned H2
    page boundaries.
-   Defined background autosave and explicit stale-editor protection.
-   Defined incomplete Memory draft behavior:
    -   incomplete drafts do not appear as normal Timeline Memories;
    -   Timeline may offer `Continue Draft`;
    -   Continue Draft resolves the most recently modified incomplete
        draft first;
    -   Add Memory warns when an incomplete draft already exists and
        permits Continue Draft or Create Another.
-   Defined PRESENT-readiness validation with specific blocking
    messages.
-   Defined stable Memory directory allocation using:
    -   zero-padded numeric stable ID;
    -   random 10-digit suffix;
    -   no automatic directory rename after title changes.
-   Defined Markdown as durable source of truth and SQLite as the
    application index/representation.
-   Defined external Markdown reconciliation and manual-resolution
    behavior for ambiguity.
-   Defined atomic/safe Markdown replacement ordering.
-   Defined preservation of original JPEG/HEIC uploads.
-   Defined upload-time generation of PRESENT and thumbnail derivatives.
-   Defined image-processing acceptance around the Raspberry Pi's
    existing shell-accessible `magick` and `heif-convert` tools.
-   Defined approximately quality-90 normalized/presentation JPEG output
    and a 2560 px maximum PRESENT long edge.
-   Defined no image transformation during normal GET requests.
-   Defined MVP deployment assumptions for Raspberry Pi 4, Rails on port
    8086, SQLite, filesystem storage, Cloudflare Tunnel, and direct
    trusted-LAN access.
-   Added formal product/design documentation:
    -   Product Specification
    -   UX / Information Architecture
    -   Wireframes
    -   Architecture
    -   Feature Specifications
    -   Acceptance Criteria
-   Added repository maintenance guidance for future engineers and AI
    coding agents.
-   Established Architecture Decision Records as the mechanism for
    preserving significant technical reasoning over time.

### Deferred

The following remain intentionally outside MVP:

-   public/shareable Memory URLs;
-   QR-code sharing;
-   image-library browser;
-   unused-image cleanup UI;
-   Memory deletion/recovery;
-   image deletion/recovery;
-   three-image and arbitrary page layouts;
-   full layout selector/preview UI;
-   drag-and-drop page ordering;
-   sophisticated Timeline collision detection;
-   search;
-   maps/places;
-   people indexing;
-   statistics;
-   PowerPoint import;
-   automated backups;
-   application-level users/roles.

## Changelog Guidelines

Add an entry when a change materially affects one or more of:

-   user-visible behavior;
-   supported workflows;
-   persistence/data compatibility;
-   Markdown format;
-   deployment requirements;
-   significant dependencies;
-   architectural contracts;
-   recovery/data-safety behavior.

Usually do not add entries for:

-   internal refactoring with unchanged behavior;
-   test-only changes;
-   minor CSS tuning;
-   comments;
-   renames without compatibility impact;
-   routine dependency patch updates.

When releases begin, move applicable Unreleased entries under a dated
version heading:

``` text
## 0.1.0 - YYYY-MM-DD
```

Keep entries concise and describe outcomes rather than implementation
trivia.
