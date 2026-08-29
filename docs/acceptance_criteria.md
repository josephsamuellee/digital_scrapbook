# Acceptance Criteria

## 1. Purpose

This document defines objective MVP acceptance criteria for the
application specified by:

-   `product_spec.md`
-   `ux_information_architecture.md`
-   `wireframes.md`
-   `architecture.md`
-   `feature_specifications.md`

Acceptance criteria define how an engineer or AI coding agent can
determine that an implementation is complete and correct.

They are intentionally focused on observable behavior and architectural
invariants rather than subjective visual judgment.

## 2. Verification Labels

-   **\[AUTO\]** --- should normally be verified by automated unit,
    request, integration, or system tests.
-   **\[MANUAL\]** --- requires a human/device check because the
    criterion concerns browser/device interaction or visual usability
    that is not usefully reduced to a brittle pixel test.
-   **\[ARCH\]** --- architectural invariant that should be enforced by
    automated tests where practical and confirmed by code review.

AI coding agents should not invent screenshot thresholds or subjective
visual scores for MANUAL criteria.

## 3. MVP Browser and Device Targets

Primary acceptance targets:

-   current Safari on iPhone;
-   current Chrome on desktop;
-   current Safari on desktop.

For mobile PRESENT layout, manually verify an iPhone-class landscape
viewport with an aspect ratio around 19.5:9. Do not tie acceptance to
one specific iPhone model.

Firefox and Edge should be supported through standards-compliant
implementation where practical, but are not required MVP acceptance-test
targets.

------------------------------------------------------------------------

# AC-F1 --- Timeline

## AC-F1-01 --- Empty Timeline

**\[AUTO\]**

Given no PRESENT-ready Memories exist\
When the user loads `/`\
Then:

-   the page displays `Our Memories`;
-   the page displays `No memories yet.`;
-   an Add Memory action is available;
-   the appearance control is available;
-   no empty year axis is rendered.

## AC-F1-02 --- Reverse chronological years

**\[AUTO\]**

Given PRESENT-ready Memories exist in 2024 and 2026\
When the Timeline renders\
Then:

-   2026 appears before 2024;
-   no 2025 year section is rendered unless a Memory representation
    belongs to 2025.

## AC-F1-03 --- Current empty year is omitted

**\[AUTO\]**

Given the current year contains no PRESENT-ready Memory\
When the Timeline renders\
Then the current year is not rendered solely because it is the current
year.

## AC-F1-04 --- Multi-day proportional positioning

**\[AUTO\]**

Given a Memory has valid start and end dates within one year\
When its Timeline geometry is calculated\
Then:

-   the start position is proportional to its actual start day within
    that year;
-   the end position is proportional to its actual end day within that
    year;
-   the duration segment preserves chronological scale relative to the
    complete year.

## AC-F1-05 --- Leap-year calculation

**\[AUTO\]**

Given a Memory occurs during a leap year\
When Timeline positions are calculated\
Then the year is treated as 366 days rather than 365.

## AC-F1-06 --- Single-day marker

**\[AUTO\]**

Given a Memory's start and end date represent one day\
When the Timeline renders\
Then it uses a point/circle-style marker rather than requiring a
mathematically zero-width duration segment.

## AC-F1-07 --- Minimum visible marker

**\[AUTO\]**

Given a valid very-short Memory duration\
When the calculated segment would be too narrow to remain
visibly/touchably useful\
Then the renderer may apply the documented minimum visible width without
changing the underlying stored dates.

## AC-F1-08 --- Primary Memory label content

**\[AUTO\]**

Given a normal primary-year Memory representation\
When it renders\
Then the label contains:

-   the key-photo thumbnail;
-   the Memory title;

and does not require:

-   textual exact dates;
-   location;
-   summary;
-   page count.

## AC-F1-09 --- Thumbnail derivative

**\[ARCH\]**

Given a valid `_thumb.jpg` derivative exists\
When Timeline renders a Memory thumbnail\
Then it references the thumbnail derivative rather than the original or
`_present` image.

No image transformation occurs during the Timeline GET request.

## AC-F1-10 --- Memory label anchor

**\[AUTO\]**

Given a multi-day Memory\
When Timeline label geometry is generated\
Then its connector/label is associated approximately with the midpoint
of the duration segment rather than falsely moving the segment itself.

## AC-F1-11 --- Timeline interaction

**\[AUTO\]**

Given a Timeline Memory representation\
When the user activates its supported marker/label interaction target\
Then the browser navigates to PRESENT for the same stable Memory ID.

## AC-F1-12 --- Cross-year primary representation

**\[AUTO\]**

Given a Memory spans two calendar years\
When one year contains a greater number of days of that Memory\
Then:

-   both years contain a representation of the Memory;
-   the longer-duration year receives the primary full label;
-   the shorter-duration year receives a subordinate continuation
    representation;
-   both representations resolve to the same stable Memory.

## AC-F1-13 --- Equal cross-year duration

**\[AUTO\]**

Given a cross-year Memory has an equal duration portion in both years\
When its primary year is selected\
Then the more recent year is selected as primary.

## AC-F1-14 --- Q4 continuation

**\[AUTO\]**

Given a Memory begins in Q4 and continues into the following year, and
the Q4 portion is the secondary/shorter representation\
When the prior year renders\
Then a continuation marker is present near the applicable Q4 endpoint
and may use the compact key thumbnail without duplicating a full
competing primary label.

## AC-F1-15 --- No horizontal year scrolling

**\[MANUAL\]**

Given a populated Timeline\
When viewed in current iPhone Safari in portrait and landscape\
Then each individual year scale fits within the available viewport width
without requiring horizontal scrolling.

## AC-F1-16 --- Landscape density

**\[MANUAL\]**

Given representative low-density data consistent with the expected
application usage\
When viewed on an iPhone-class landscape viewport\
Then the Timeline remains compact enough that approximately two complete
years can be visible when Memory density permits.

This is a design target, not a pixel-perfect automated requirement.

## AC-F1-17 --- Bottom controls

**\[AUTO\]**

Given the Timeline has rendered its oldest year\
Then Add Memory, any available Continue Draft action, and the appearance
control occur after the year content rather than above the Timeline
archive.

## AC-F1-18 --- Incomplete draft exclusion

**\[AUTO\]**

Given a Memory is incomplete according to PRESENT-readiness validation\
When Timeline renders\
Then that Memory is not rendered as a normal Timeline Memory.

## AC-F1-19 --- Continue Draft visibility

**\[AUTO\]**

Given at least one incomplete draft exists\
When Timeline renders\
Then a `Continue Draft` action is available.

Given no incomplete draft exists\
Then `Continue Draft` is not required to be shown.

## AC-F1-20 --- Continue most recent draft

**\[AUTO\]**

Given multiple incomplete drafts exist\
When the user selects `Continue Draft`\
Then EDIT opens the most recently modified incomplete draft.

If that draft later becomes complete, the next Continue Draft action
resolves to the next-most-recent incomplete draft.

## AC-F1-21 --- Corrupt Memory isolation

**\[AUTO\]**

Given one Memory cannot be parsed or reconciled\
And another valid Memory exists\
When Timeline renders\
Then the valid Memory remains usable and the corrupt Memory does not
cause the complete Timeline request to fail.

The corrupt condition is logged.

------------------------------------------------------------------------

# AC-F2 --- Memory Presentation

## AC-F2-01 --- PRESENT readiness gate

**\[AUTO\]**

Given an incomplete Memory\
When the user attempts to enter PRESENT through `View Presentation`\
Then navigation is blocked and EDIT identifies the currently unresolved
requirements.

## AC-F2-02 --- Validation feedback

**\[AUTO\]**

Given a Memory is missing one or more required PRESENT-ready values\
When readiness validation occurs\
Then the user receives specific blocking messages for the
missing/invalid items rather than only a generic invalid-Memory error.

Possible blocking conditions include:

-   missing title;
-   missing/invalid start date;
-   end date before start date;
-   no authored page;
-   no successfully processed picture;
-   missing/invalid key photo.

Only applicable failures need to be displayed.

## AC-F2-03 --- Complete Memory opens

**\[AUTO\]**

Given all PRESENT-readiness requirements are satisfied\
When the user selects `View Presentation`\
Then pending valid changes are persisted and PRESENT opens for the same
stable Memory.

## AC-F2-04 --- Title page

**\[AUTO\]**

Given a complete Memory\
When PRESENT opens\
Then the first presentation state is a generated title page containing
the structured Memory title and applicable subtitle/date information.

## AC-F2-05 --- Authored page sequence

**\[AUTO\]**

Given `memory.md` contains ordered application-managed H2 sections\
When PRESENT is generated\
Then authored pages appear in the same order.

## AC-F2-06 --- One landscape image layout

**\[MANUAL\]**

Given a page contains one typical 3:2 or 4:3 landscape image and
commentary\
When viewed on an iPhone-class \~19.5:9 landscape viewport\
Then:

-   the image preserves its aspect ratio;
-   the image is not stretched to fill the viewport;
-   meaningful outer whitespace remains;
-   the image receives visual priority;
-   commentary remains readable in the remaining horizontal region.

Do not require a pixel-perfect 70/30 or 60/40 split.

## AC-F2-07 --- Image vertical fit

**\[MANUAL\]**

Given a supported landscape image page\
When PRESENT renders\
Then the image normally occupies approximately 80--90% or less of usable
vertical page height rather than touching/filling the entire viewport
vertically.

This is a visual design check, not an automated pixel threshold.

## AC-F2-08 --- Two portrait image layout

**\[MANUAL\]**

Given a page contains two portrait-oriented images and commentary\
When PRESENT renders in landscape\
Then:

-   both images are visible together;
-   neither is stretched;
-   their aspect ratios are preserved;
-   they fit within the landscape composition;
-   commentary remains available to the right.

## AC-F2-09 --- PRESENT derivatives

**\[ARCH\]**

Given valid `_present.jpg` derivatives exist\
When PRESENT renders images\
Then it uses the PRESENT derivatives rather than full-resolution
originals.

## AC-F2-10 --- No runtime image processing

**\[ARCH\]**

When a PRESENT GET request is handled\
Then the request does not invoke `magick`, `heif-convert`, or another
image transformation pipeline to generate presentation assets.

## AC-F2-11 --- Phone portrait overlay

**\[MANUAL\]**

Given PRESENT is opened in iPhone Safari in portrait orientation\
Then the application displays a lightweight instruction to rotate the
device rather than reflowing the scrapbook into a portrait presentation.

## AC-F2-12 --- Desktop scaling

**\[MANUAL\]**

Given PRESENT is opened in current desktop Chrome or Safari\
Then the landscape composition is centered/scaled to fit available space
without fundamentally reflowing the scrapbook layout.

## AC-F2-13 --- Visible navigation controls

**\[MANUAL\]**

Given an authored presentation page\
Then Previous/Next controls are visible but visually subordinate to
content and are positioned toward the lower left/right rather than
vertically centered.

## AC-F2-14 --- Center is not a navigation target

**\[AUTO\]**

Given PRESENT is displayed\
When the user interacts with the center content region\
Then the application does not treat the entire left/right half of the
viewport as an unconditional page-navigation target.

## AC-F2-15 --- Swipe navigation

**\[MANUAL\]**

Given PRESENT is open in iPhone Safari landscape\
When the user swipes left/right\
Then the presentation moves in the corresponding page direction.

## AC-F2-16 --- Keyboard navigation

**\[AUTO\]**

Given PRESENT is focused in a desktop browser\
Then:

-   Right Arrow advances;
-   Left Arrow goes backward;
-   `l` advances;
-   `h` goes backward.

## AC-F2-17 --- Page position

**\[AUTO\]**

Given a multi-page Memory\
When an authored page is shown\
Then a consistent page-position indicator such as `4 / 17` is displayed.

The generated title page participates consistently in the chosen count
convention.

## AC-F2-18 --- Generated end state

**\[AUTO\]**

Given the user advances past the final authored page\
Then a generated end state appears with:

-   `Back to Timeline`;
-   `Edit Memory`.

Going backward returns to the final authored page.

## AC-F2-19 --- No global PRESENT header

**\[AUTO\]**

Given PRESENT is active\
Then the standard TIMELINE/EDIT global navigation header is not
rendered.

## AC-F2-20 --- Minimal transitions

**\[MANUAL\]**

Given normal page navigation\
Then navigation does not require decorative page-flip or other expensive
animation and feels immediate on the LAN.

------------------------------------------------------------------------

# AC-F3 --- Memory Editor and Drafts

## AC-F3-01 --- New Memory allocation

**\[AUTO\]**

Given the user creates a new Memory\
When the new draft is initialized\
Then:

-   it receives a stable integer ID;
-   its directory begins with that ID zero-left-padded to three digits;
-   the directory also contains a random 10-digit suffix;
-   the directory does not require a title to be known first.

Example shape:

``` text
043-5831047291/
```

## AC-F3-02 --- Stable directory

**\[AUTO\]**

Given a draft directory has been allocated\
When the Memory title later changes\
Then the application does not automatically rename the Memory directory.

## AC-F3-03 --- Empty abandoned draft allowed

**\[AUTO\]**

Given a new Memory directory/record was created\
And the user leaves without completing it\
Then the application may retain the empty/incomplete draft without
automatic deletion.

The draft does not appear as a normal Timeline Memory.

## AC-F3-04 --- Existing-draft warning

**\[AUTO\]**

Given at least one incomplete draft exists\
When the user selects Add Memory\
Then the application warns that an unfinished Memory already exists and
offers actions equivalent to:

-   Continue Draft;
-   Create Another.

The user may explicitly create another draft.

## AC-F3-05 --- Metadata fields

**\[AUTO\]**

EDIT provides structured controls for at least:

-   title;
-   start date;
-   optional end date;
-   subtitle/title-page secondary information;
-   key photo.

## AC-F3-06 --- Page strip

**\[MANUAL\]**

Given a Memory with authored pages\
Then EDIT shows a page strip below metadata and above the selected-page
editor containing:

-   title-page representation;
-   authored-page representations;
-   Add Page affordance;
-   clear selected-page indication.

## AC-F3-07 --- Add blank page

**\[AUTO\]**

When the user adds an authored page\
Then a new page is created with a blank page/H2 heading rather than
guessed title/date content.

## AC-F3-08 --- Delete confirmation

**\[AUTO\]**

Given an authored page exists\
When the user requests page deletion\
Then a confirmation is required before deletion is persisted.

## AC-F3-09 --- Page deletion does not delete images

**\[AUTO\]**

Given a page references an image\
When the page is deleted\
Then the page section is removed from the Memory document after
confirmation, but the image file itself is not automatically deleted.

## AC-F3-10 --- Reorder pages

**\[AUTO\]**

Given at least two authored pages\
When Move Earlier/Move Later is used\
Then the persisted H2 section order changes accordingly.

## AC-F3-11 --- One-page editor

**\[AUTO\]**

Given an authored page is selected\
Then the primary Markdown editing surface edits that page rather than
requiring the user to edit the complete raw Memory document.

## AC-F3-12 --- H2 protection

**\[AUTO\]**

Given the user types an H2 inside a selected-page editor\
When validation/save occurs\
Then:

-   it does not silently create another Memory Page;
-   the user receives a warning;
-   the invalid H2 is handled according to the documented Markdown
    sanitization behavior.

## AC-F3-13 --- Upload appends to page Markdown

**\[AUTO\]**

Given a supported image successfully uploads/processes\
Then the resulting Markdown image reference is appended to the
selected page Markdown.

## AC-F3-14 --- No persistent image library

**\[MANUAL\]**

MVP EDIT does not require a persistent uploaded-image gallery/library
panel.

## AC-F3-15 --- No image deletion UI

**\[AUTO\]**

MVP EDIT does not expose a normal per-image delete operation.

## AC-F3-16 --- Autosave interval

**\[AUTO\]**

Given valid unsaved changes remain in EDIT\
Then the application attempts background persistence no less frequently
than once per minute.

It may save sooner through debouncing or navigation events.

## AC-F3-17 --- Save-state indicator

**\[AUTO\]**

During persistence, EDIT indicates `Saving…` or equivalent.

After successful persistence/indexing, EDIT indicates `Saved` or
equivalent.

On failure, EDIT must not report `Saved`.

## AC-F3-18 --- Page switch persistence

**\[AUTO\]**

Given the current page contains pending valid edits\
When the user switches to another page\
Then pending changes are persisted as part of or before the page
transition according to the editor's autosave behavior.

## AC-F3-19 --- Incomplete draft autosave

**\[AUTO\]**

Given a Memory does not yet satisfy PRESENT-readiness requirements\
When autosave occurs\
Then valid incomplete draft state may still be persisted.

PRESENT readiness and draft persistence are separate concerns.

## AC-F3-20 --- External modification conflict

**\[AUTO\]**

Given EDIT loaded source version A\
And `memory.md` is externally modified to version B\
When the stale browser attempts autosave\
Then:

-   autosave is rejected;
-   version B is not overwritten;
-   the browser does not claim Saved;
-   the user is told that the Memory changed outside the editor and must
    be reloaded.

## AC-F3-21 --- Conflict warning consequence

**\[AUTO\]**

The external-change warning makes clear that current browser edits
cannot be saved until reload.

MVP does not attempt automatic merge or recovery of the stale browser
edits.

------------------------------------------------------------------------

# AC-F4 --- Markdown Persistence and Reconciliation

## AC-F4-01 --- YAML front matter

**\[AUTO\]**

Given a Memory is persisted\
Then `memory.md` contains valid YAML front matter including its stable
ID and portable Memory metadata.

## AC-F4-02 --- Markdown is authoritative

**\[AUTO\]**

Given valid Markdown metadata disagrees with duplicated SQLite metadata\
When reconciliation occurs outside a stale active-editor conflict\
Then Markdown metadata wins and SQLite is reindexed from Markdown.

## AC-F4-03 --- SQLite source association

**\[AUTO\]**

Each indexed Memory record retains the source filename/path association
needed to identify its corresponding Markdown source.

## AC-F4-04 --- Stable ID matching first

**\[AUTO\]**

Given an externally modified/renamed Memory file contains a valid stable
ID\
When reconciliation occurs\
Then stable ID is preferred over title similarity for matching the
SQLite record.

## AC-F4-05 --- Source-path update

**\[AUTO\]**

Given a Memory source is externally renamed/moved within supported
data-root behavior\
And its stable ID unambiguously matches an existing SQLite record\
When reconciled\
Then the SQLite source association can be updated without changing the
Memory's stable identity.

## AC-F4-06 --- Ambiguous reconciliation

**\[AUTO\]**

Given reconciliation cannot unambiguously determine identity\
Then the application does not silently merge/overwrite Memories based
solely on similar titles.

The condition is logged/surfaced for manual resolution.

## AC-F4-07 --- External metadata edit

**\[AUTO\]**

Given `memory.md` title changes externally from `Taiwan` to
`Taiwan 2026`\
And its stable ID remains valid\
When change detection/reconciliation runs\
Then the corresponding SQLite title becomes `Taiwan 2026`.

## AC-F4-08 --- Rebuildability

**\[AUTO\]**

Given a valid Memory directory with a valid `memory.md` exists but its
SQLite Memory record does not\
Then application domain code can index/import that Memory from its
Markdown metadata without requiring the original database row.

A polished rebuild UI is not required.

## AC-F4-09 --- Missing Markdown protection

**\[AUTO\]**

Given SQLite references a missing Markdown source\
When the Memory is reconciled/opened\
Then the application does not silently regenerate authoritative Markdown
from stale SQLite metadata.

## AC-F4-10 --- Invalid Markdown isolation

**\[AUTO\]**

Given one Memory contains invalid YAML/Markdown that prevents parsing\
Then unrelated valid Memories remain operable.

## AC-F4-11 --- Atomic replacement

**\[ARCH\]**

Normal Memory persistence writes a complete temporary file in the same
filesystem and replaces `memory.md` atomically after successful
write/close rather than progressively overwriting the authoritative
file.

## AC-F4-12 --- Failed temporary write

**\[AUTO\]**

Given temporary Markdown writing fails\
Then:

-   the previous valid `memory.md` remains authoritative;
-   SQLite is not updated to represent the failed new content;
-   EDIT receives a save failure.

## AC-F4-13 --- SQLite failure after Markdown success

**\[AUTO\]**

Given authoritative Markdown replacement succeeds\
And subsequent SQLite indexing fails\
Then the new Markdown remains authoritative and a later reconciliation
can restore SQLite from it.

## AC-F4-14 --- Complete-document persistence

**\[ARCH\]**

EDIT persistence may submit/reconstruct and serialize the complete small
Memory document.

MVP does not require patch-based, collaborative, operational-transform,
or per-fragment persistence infrastructure.

## AC-F4-15 --- External-change detection is cheap

**\[ARCH\]**

Change detection uses a simple deterministic mechanism such as
modification time, file size, fingerprint, or similarly lightweight
metadata.

It does not require an external indexing/search service.

------------------------------------------------------------------------

# AC-F5 --- Image Upload and Processing

## AC-F5-01 --- JPEG upload

**\[AUTO\]**

Given a valid JPEG upload\
When processing succeeds\
Then:

-   the original JPEG is preserved;
-   a `_present.jpg` derivative exists;
-   a `_thumb.jpg` derivative exists;
-   the page receives a valid image reference only after successful
    required processing.

## AC-F5-02 --- HEIC upload

**\[AUTO\]**

Given a valid HEIC upload\
When processing succeeds\
Then:

-   the original `.HEIC` file is preserved;
-   a normalized JPEG master is created;
-   a `_present.jpg` derivative is created;
-   a `_thumb.jpg` derivative is created;
-   generated images preserve correct orientation and aspect ratio.

## AC-F5-03 --- HEIC/JPEG processing implementation flexibility

**\[ARCH\]**

The Raspberry Pi already provides shell-accessible `magick` and
`heif-convert`.

MVP may use either or both where they provide the simplest maintainable
implementation.

The specification does not require one specific command-line tool.

The chosen implementation must satisfy all observable image acceptance
criteria.

Avoid adding additional heavy processing infrastructure solely to
satisfy a preference between these already-available tools.

## AC-F5-04 --- JPEG quality target

**\[AUTO\]**

Generated normalized/presentation JPEGs use approximately quality 90
according to the selected processing tool's supported quality semantics.

## AC-F5-05 --- PRESENT maximum dimension

**\[AUTO\]**

Given a source image whose long edge exceeds 2560 pixels\
When `_present.jpg` is generated\
Then its long edge is no greater than 2560 pixels and its aspect ratio
is preserved.

## AC-F5-06 --- No unnecessary upscaling

**\[AUTO\]**

Given a source image whose dimensions are already below the PRESENT
maximum\
When the derivative is generated\
Then it is not enlarged merely to reach 2560 pixels.

## AC-F5-07 --- Thumbnail generation

**\[AUTO\]**

Given a successful supported image upload\
Then `_thumb.jpg` is generated during upload processing and is
substantially smaller than the PRESENT derivative while preserving
aspect ratio.

Exact thumbnail dimensions are implementation-tunable.

## AC-F5-08 --- Semantic derivative names

**\[AUTO\]**

Generated derivative filenames use semantic suffixes such as:

``` text
_present
_thumb
```

They do not rely on PPI/DPI naming such as `_300ppi`.

## AC-F5-09 --- Filename collision

**\[AUTO\]**

Given `IMG_1234.jpg` already exists in the Memory directory\
When another upload with the same name is accepted\
Then the existing file is not overwritten and the new upload receives a
deterministic suffix such as:

``` text
IMG_1234_2.jpg
```

Its derivatives use the resolved base name.

## AC-F5-10 --- Processing indicator

**\[MANUAL\]**

Given a supported upload requires noticeable processing time\
Then EDIT visibly indicates `Processing…` or equivalent until
success/failure is known.

## AC-F5-11 --- Duplicate upload prevention

**\[AUTO\]**

While one upload is actively processing through a control\
Then accidental duplicate submission through that same control is
prevented.

## AC-F5-12 --- Processing failure message

**\[AUTO\]**

Given the selected image-processing command fails\
Then EDIT displays a message equivalent to:

``` text
Image processing failed: <useful sanitized processing message>
```

A relevant safe message from `magick`, `heif-convert`, or the selected
processing layer may be included.

## AC-F5-13 --- Sensitive diagnostic separation

**\[AUTO\]**

Given image processing fails\
Then detailed diagnostics may be logged server-side, but browser-visible
output does not unnecessarily expose arbitrary server filesystem paths
or complete internal shell commands.

## AC-F5-14 --- Failed processing does not alter Markdown

**\[AUTO\]**

Given image processing fails\
Then:

-   no broken image reference is inserted into page Markdown;
-   existing editor text remains unchanged by the failed insertion
    operation.

## AC-F5-15 --- No processing on GET

**\[ARCH\]**

TIMELINE, PRESENT, and EDIT GET requests do not invoke image
conversion/resizing to satisfy normal page rendering.

Required derivatives are created at upload/change time.

------------------------------------------------------------------------

# AC-F6 --- Appearance

## AC-F6-01 --- Default dark mode

**\[AUTO\]**

Given no appearance preference has previously been stored\
When the application loads\
Then dark mode is the default.

## AC-F6-02 --- Appearance toggle

**\[AUTO\]**

Given the user changes Dark/Light appearance from Timeline\
Then the application applies the selected supported appearance.

## AC-F6-03 --- Browser persistence

**\[AUTO\]**

Given the user selects an appearance\
When the application is subsequently reopened in the same browser
context\
Then the preference persists without requiring an application user
account.

## AC-F6-04 --- EDIT dark support

**\[MANUAL\]**

EDIT is usable and readable in the default dark appearance.

## AC-F6-05 --- PRESENT dark surroundings

**\[MANUAL\]**

PRESENT uses dark surrounding/background treatment by default without
requiring the authored photograph itself to be modified.

------------------------------------------------------------------------

# AC-F7 --- Access and Deployment

## AC-F7-01 --- LAN access

**\[MANUAL\]**

Given the Rails service is running in the intended Pi deployment\
When a trusted LAN client accesses:

``` text
http://192.168.12.111:8086
```

Then the application is usable without requiring Cloudflare-specific
request headers.

## AC-F7-02 --- Cloudflare tunnel access

**\[MANUAL\]**

Given `cloudflared` is configured to forward external traffic to the
Rails service\
When an authenticated external request reaches the application through
Cloudflare\
Then the same application routes and Memory behavior operate correctly.

## AC-F7-03 --- No Rails account requirement

**\[AUTO\]**

MVP does not require a Rails User/account/login model to access
application features after the deployment boundary has allowed the
request.

## AC-F7-04 --- Independent data root

**\[ARCH\]**

The application uses its own configured SQLite database and Memory data
root, separate from other Raspberry Pi applications.

## AC-F7-05 --- Configurable data path

**\[ARCH\]**

The absolute application data-root path is configuration/deployment
state rather than being hard-coded throughout domain logic.

------------------------------------------------------------------------

# AC-F8 --- Error, Recovery, and Non-Destructive Behavior

## AC-F8-01 --- Save failure visibility

**\[AUTO\]**

Given autosave fails\
Then EDIT visibly reports failure and does not claim Saved.

## AC-F8-02 --- External conflict is non-destructive

**\[AUTO\]**

Given a stale editor conflicts with an external Markdown edit\
Then the external authoritative file is not overwritten.

## AC-F8-03 --- No automatic Memory deletion

**\[AUTO\]**

MVP does not automatically delete abandoned draft directories or expose
normal destructive Memory deletion without a later deletion/recovery
specification.

## AC-F8-04 --- No automatic image deletion

**\[AUTO\]**

MVP does not automatically delete unused images merely because pages or
Markdown references change.

## AC-F8-05 --- No automated backup claim

**\[ARCH\]**

Autosave is not presented or implemented as a backup system.

Automated backup functionality is outside MVP.

## AC-F8-06 --- Logging

**\[ARCH\]**

The application uses conventional Rails/server logging sufficient to
diagnose:

-   persistence failures;
-   reconciliation events/conflicts;
-   malformed Memories;
-   image-processing failures.

No external telemetry/error-reporting service is required.

------------------------------------------------------------------------

# AC-F9 --- Repository and Maintainability

## AC-F9-01 --- Required documentation

**\[ARCH\]**

The repository contains or incorporates the authoritative project
documentation:

``` text
README.md
docs/
  product_spec.md
  ux_information_architecture.md
  wireframes.md
  architecture.md
  feature_specifications.md
  acceptance_criteria.md
```

Equivalent paths are acceptable if clearly documented.

## AC-F9-02 --- Setup documentation

**\[ARCH\]**

README/project documentation identifies:

-   required Ruby/Rails environment;
-   required image-processing commands/dependencies;
-   application data-root configuration;
-   SQLite initialization/setup;
-   local development command;
-   test command;
-   deployment assumptions relevant to port 8086/cloudflared.

## AC-F9-03 --- Conventional project commands

**\[ARCH\]**

Where appropriate for the Rails application, conventional commands such
as the following are provided/documented:

``` text
bin/setup
bin/dev
bin/test
```

## AC-F9-04 --- No unnecessary architecture expansion

**\[ARCH\]**

MVP implementation does not introduce without an explicit documented
need:

-   React/SPA architecture;
-   Redis;
-   Sidekiq;
-   external database;
-   external object storage;
-   external search;
-   application analytics;
-   application-level user system.

## AC-F9-05 --- Documentation changes with contracts

**\[ARCH\]**

If implementation requires changing an architectural or feature contract
defined by the project documents, the relevant documentation is updated
rather than allowing implementation and specification to silently
diverge.

------------------------------------------------------------------------

# 4. End-to-End MVP Acceptance Scenario

## AC-E2E-01 --- Create, author, present, retrieve

**\[AUTO + MANUAL\]**

Starting from an application with no PRESENT-ready Memories:

1.  Open TIMELINE.
2.  Select Add Memory.
3.  Confirm a stable ID and `NNN-RANDOM10DIGITS` directory are
    allocated.
4.  Enter a title and valid dates.
5.  Add an authored page.
6.  Upload a JPEG or HEIC.
7.  Confirm processing feedback appears when processing is noticeable.
8.  Confirm original and required derivatives are persisted.
9.  Confirm the image reference is inserted into the selected page.
10. Confirm autosave successfully writes `memory.md`.
11. Confirm YAML front matter contains the stable ID and portable
    metadata.
12. Confirm SQLite indexes the same Memory and source association.
13. Satisfy all PRESENT-readiness requirements.
14. Select View Presentation.
15. Confirm generated title page appears.
16. Confirm authored page(s) render in the supported landscape layout
    without image stretching.
17. Navigate using visible controls.
18. On iPhone Safari, verify swipe navigation.
19. On desktop, verify Arrow and `h`/`l` navigation.
20. Reach the generated end state.
21. Return to Timeline.
22. Confirm the Memory appears in the correct year and proportional date
    position with key thumbnail and title.
23. Confirm no runtime image conversion occurs during Timeline or
    PRESENT retrieval.

Passing this scenario demonstrates the minimum useful integrated MVP.

------------------------------------------------------------------------

# 5. Draft Lifecycle Acceptance Scenario

## AC-E2E-02 --- Incomplete draft

**\[AUTO\]**

1.  Select Add Memory.
2.  Allow the application to allocate a stable draft.
3.  Leave the Memory incomplete.
4.  Return to Timeline.
5.  Confirm the incomplete Memory does not appear as a normal Timeline
    item.
6.  Confirm Continue Draft is available.
7.  Select Continue Draft.
8.  Confirm the most recently modified incomplete draft opens.
9.  Return and select Add Memory while a draft exists.
10. Confirm the application offers Continue Draft or Create Another.
11. Explicitly create another draft.
12. Confirm the prior draft remains intact.
13. Confirm neither incomplete draft appears as a normal Timeline
    Memory.
14. Confirm Continue Draft resolves drafts from most recently modified
    backward as drafts become complete.

------------------------------------------------------------------------

# 6. External Markdown Reconciliation Acceptance Scenario

## AC-E2E-03 --- Portable external edit

**\[AUTO\]**

1.  Create and save a valid Memory through EDIT.
2.  Record its stable ID and SQLite metadata.
3.  Close/reload as needed so no stale active editor conflict is
    involved.
4.  Modify portable metadata directly in `memory.md`.
5.  Preserve the stable YAML ID.
6.  Trigger normal application reconciliation.
7.  Confirm the external Markdown metadata becomes the SQLite indexed
    metadata.
8.  Confirm the discrepancy/reindex is logged.
9.  Confirm the stable Memory ID does not change.
10. Confirm Timeline/PRESENT use the reconciled metadata.

------------------------------------------------------------------------

# 7. Stale Editor Protection Acceptance Scenario

## AC-E2E-04 --- Do not overwrite external changes

**\[AUTO\]**

1.  Open a Memory in EDIT.
2.  Make an unsaved browser edit.
3.  Modify the same `memory.md` externally.
4.  Allow/trigger browser autosave.
5.  Confirm autosave is rejected.
6.  Confirm the externally modified `memory.md` remains unchanged by the
    stale browser.
7.  Confirm EDIT does not show Saved.
8.  Confirm EDIT instructs the user to reload before continuing.
9.  Confirm no automatic merge is attempted.

------------------------------------------------------------------------

# 8. Cross-Year Timeline Acceptance Scenario

## AC-E2E-05 --- Cross-year Memory

**\[AUTO + MANUAL\]**

Given a Memory spanning December into January:

1.  Confirm the Memory remains one stable Memory.
2.  Confirm representations appear in both affected year timelines.
3.  Confirm each year's duration segment corresponds to that year's
    portion.
4.  Confirm the year containing the longer portion receives the primary
    key-photo/title representation.
5.  Confirm the shorter side receives a subordinate continuation
    representation.
6.  If durations are equal, confirm the newer year is primary.
7.  Confirm both representations open the same PRESENT route/stable ID.
8.  Manually confirm the continuation treatment does not visually
    compete with the primary representation.

------------------------------------------------------------------------

# 9. Definition of MVP Complete

The MVP is acceptance-ready when:

-   all applicable **\[AUTO\]** criteria pass;
-   all **\[ARCH\]** invariants have been verified by tests and/or code
    review;
-   primary **\[MANUAL\]** checks pass in current iPhone Safari and
    current desktop Chrome/Safari;
-   all end-to-end scenarios pass;
-   known failures are documented rather than silently ignored;
-   no deferred feature is required to complete the core create →
    autosave → present → Timeline workflow.

Subjective visual refinement beyond the documented wireframe invariants
is not a blocker unless it prevents the required interaction or makes
the supported viewport unusable.
