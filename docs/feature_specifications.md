# Feature Specifications

## 1. Purpose

This document defines MVP feature behavior for the application described by:

- `product_spec.md`
- `ux_information_architecture.md`
- `wireframes.md`
- `architecture.md`

It translates product, UX, and architectural decisions into independently implementable feature contracts.

This document is intentionally more behavioral than `architecture.md` and more precise than the wireframes. It should tell an engineer or AI coding agent what each MVP feature must do without prescribing unnecessary implementation details.

Detailed acceptance criteria and test cases should be derived from these specifications.

---

# F1 — Timeline

## F1.1 Purpose

TIMELINE is the homepage and primary Memory retrieval interface.

It provides a chronological visual index of Memories without behaving like a photo gallery or file browser.

## F1.2 Route

Conceptual route:

```text
GET /
```

## F1.3 Page title

Display:

> **Our Memories**

## F1.4 Year generation

Render only years containing at least one Memory representation.

Do not generate empty years merely because they fall between existing years or because they are the current year.

Order years reverse chronologically.

## F1.5 Year scale

Each year represents Jan 1 through Dec 31 across the available Timeline width.

The year must fit without horizontal scrolling.

Multi-day Memory duration is proportionally positioned using actual dates relative to the number of days in that year.

Conceptually:

```text
position = (day_of_year - 1) / (days_in_year - 1)
```

Leap years must use their actual day count.

Exact CSS/geometry implementation is not prescribed.

## F1.6 Quarter markers

Use quiet quarter divisions sufficient to orient the user.

Do not render month-by-month labels in MVP.

The year label serves as the left-side context; Q2/Q3/Q4 divisions may be visually emphasized more than Q1 labeling.

## F1.7 Multi-day Memory marker

A multi-day Memory is rendered as a duration segment between its proportional start and end positions.

Duration is the primary mathematically meaningful Timeline visualization.

Do not shift the segment to avoid label collisions.

## F1.8 Single-day Memory marker

A single-day Memory is rendered as a small visible circle/point.

The visible marker may be slightly larger than strict proportional geometry would imply.

It should be visually distinguishable from quarter dividers and provide a usable interaction target.

## F1.9 Minimum marker visibility

Very short multi-day Memories may use a minimum visible marker width so they remain recognizable/tappable.

This visual minimum must not change the underlying date semantics.

## F1.10 Memory label

The primary-year Memory representation includes:

- small key-photo thumbnail;
- Memory title.

Do not normally display:

- exact date text;
- summary;
- location;
- page count;
- GPS data.

The thumbnail should be approximately two to three lines of text high, subject to wireframe tuning.

Use the pre-generated thumbnail derivative rather than loading the full original/PRESENT image.

## F1.11 Label anchor

The Memory label is visually associated with approximately the midpoint of the duration segment.

The label may use a short connector from the midpoint to the photo/title.

## F1.12 Interaction

The visible duration marker, connector, thumbnail, and title conceptually form one interaction target.

Selecting/tapping the Memory navigates to PRESENT.

Provide a touch target larger than very small visible markers.

## F1.13 Overlapping Memories

MVP should keep Memory duration segments on the same primary horizontal year axis where practical.

Labels may be vertically staggered.

Sophisticated collision detection is deferred.

If deterministic ordering is required, earlier-starting Memories receive the higher/earlier label position before later-starting overlapping Memories.

Do not falsify date positions to solve collisions.

## F1.14 Cross-year Memory

A Memory may span Dec → Jan and remains one Memory.

It is represented in both affected year timelines.

Determine which year contains the longer portion of the Memory.

### Primary year

The year containing the longer duration receives the normal full Memory label:

- applicable duration segment;
- key-photo thumbnail;
- title.

### Secondary year

The shorter-duration year receives a continuation representation rather than duplicating the full label.

The continuation marker opens the same Memory.

For a Memory continuing from Q4 into the following year, the prior-year Q4 continuation may retain a compact thumbnail at the end of that year when visually useful, but should remain subordinate to the primary-year representation.

If the durations are exactly equal, prefer the more recent year as the primary representation.

## F1.15 Responsive behavior

TIMELINE supports:

- phone portrait;
- phone landscape;
- desktop browser.

Portrait compresses the Timeline into available width.

Do not require rotation.

Do not introduce horizontal scrolling for one year.

## F1.16 Bottom controls

After the oldest rendered year, display:

- `Add Memory`;
- `Continue Draft`, when at least one incomplete draft exists;
- Dark/Light appearance control.

`Add Memory` navigates to EDIT in new-Memory state. When an incomplete
draft already exists, Add Memory warns and offers Continue Draft or
Create Another.

`Continue Draft` opens the most recently modified incomplete draft.

Theme preference persists in the browser.

Default theme is dark.

## F1.17 Empty state

When no Memories exist:

```text
Our Memories

No memories yet.

+ Add Memory

Appearance: Dark / Light
```

Do not render an empty current-year Timeline.

## F1.18 Error isolation

A corrupt/unparseable Memory should not prevent unrelated Memories from rendering.

Log the error.

The Timeline may omit or mark the affected Memory according to the simplest safe implementation.

---

# F2 — Memory Presentation

## F2.1 Purpose

PRESENT displays one Memory as a sequence of landscape scrapbook pages suitable for the owner to show another person from a phone or browser.

It is not a vertically scrolling article.

## F2.2 Route

Conceptual route:

```text
GET /memories/:id
```

Stable Memory ID resolves the Memory.

## F2.3 Source

PRESENT parses the authoritative `memory.md` server-side after performing any required stale-source reconciliation.

## F2.4 Presentation sequence

A Memory consists of:

1. generated title page;
2. authored Memory Pages;
3. generated end state.

Only one presentation page/state is visible at a time.

## F2.5 Title page

Generate the first page from structured metadata.

Display:

- centered Memory title;
- centered one-line subtitle/date text beneath it.

The title page is not an authored H2 section.

## F2.6 Authored page boundaries

Each application-managed H2 section in Markdown represents one authored Memory Page.

The H2 page heading belongs to that page.

## F2.7 MVP layout model

MVP supports two primary authored page compositions:

### Layout A — one landscape image + commentary

Supported source-image orientations/aspect ratios include typical landscape:

- approximately 3:2;
- approximately 4:3.

The image:

- preserves its original aspect ratio;
- is never stretched;
- should normally occupy roughly 80–90% of available vertical page height at most;
- should retain meaningful outer whitespace;
- should not be forced to fill the entire presentation viewport.

The commentary occupies the remaining horizontal region.

The exact image/text split is responsive to the source aspect ratio and available viewport rather than hard-coded to one percentage.

Initial visual intent:

- roughly 10% breathing room from relevant outer page edges where practical;
- image receives visual priority;
- text remains readable;
- a clear gap separates image and text.

A typical 3:2 image may result in an approximate 70/30 image/text horizontal allocation.

A 4:3 image may naturally leave more horizontal space for text, closer to approximately 60/40.

These are design targets, not strict mathematical contracts.

### Layout B — two portrait images + commentary

When a page uses two portrait-oriented images, render the two images together in the image region with commentary on the right.

Both images:

- preserve aspect ratio;
- should be visually balanced;
- should fit within the landscape page without vertical cropping/stretching.

MVP does not require arbitrary three-image layout support in PRESENT even though the long-term Memory model may allow up to three images per page.

## F2.8 Future layout selector

Architecture/UI structure should not make the MVP layouts impossible to extend.

Future EDIT may provide:

- layout dropdown/selector;
- layout preview;
- additional 1/2/3-image templates;
- explicit portrait/landscape arrangements.

Do not expose disabled future layout controls in MVP.

## F2.9 Text rendering

Render Markdown as presentation content.

Normal expectation is concise bullets.

Several paragraphs are permitted.

Do not expose Markdown syntax in PRESENT.

## F2.10 Image source

PRESENT uses pre-generated `_present` derivatives.

Do not load original high-resolution images when a valid PRESENT derivative exists.

Do not perform image transformation during GET.

## F2.11 Landscape behavior

PRESENT is landscape-first.

### Phone landscape

Use the available landscape viewport.

### Phone portrait

Show a lightweight rotate-device overlay.

Do not reflow the scrapbook into portrait.

### Desktop

Center and proportionally scale the landscape presentation composition to fit.

Do not fundamentally rearrange the authored page based on desktop window dimensions.

## F2.12 Navigation controls

Always provide subtle visible Previous and Next controls.

Place controls toward the lower left and lower right regions rather than vertically centered.

Do not make the entire left/right halves of the page clickable.

A limited edge interaction zone may be used if useful, approximately up to the outer 20% on each side, provided the center remains non-navigational and content interaction is not surprising.

## F2.13 Navigation inputs

Support:

- visible Previous/Next controls;
- swipe left/right;
- keyboard Left Arrow / Right Arrow;
- keyboard `h` / `l`.

No decorative page-flip animation is required.

Transitions should be effectively immediate/minimal.

## F2.14 Page position

Display page position such as:

```text
4 / 17
```

Keep it subtle and normally near the bottom center.

The exact counting convention should be consistent. The generated title page should be counted as part of the visible presentation sequence; the generated end state need not be counted as an authored page.

## F2.15 End state

After the final authored page, display a generated end state with:

- `Back to Timeline`;
- `Edit Memory`.

Navigating backward from the end state returns to the final authored page.

## F2.16 No persistent application header

PRESENT does not display normal TIMELINE/EDIT global chrome.

## F2.17 Theme

Presentation surroundings default to dark.

---

# F3 — Memory Editor

## F3.1 Purpose

EDIT creates and modifies Memories using structured metadata plus a page-oriented Markdown authoring interface.

The persistent source remains one Markdown file per Memory.

## F3.2 Routes

Conceptual:

```text
GET /memories/new
GET /memories/:id/edit
```

CREATE and EDIT use the same interface.

## F3.3 Editor hierarchy

Display, in order:

1. minimal EDIT header;
2. Memory metadata;
3. Memory Page thumbnail strip;
4. selected-page controls;
5. selected-page Markdown editor;
6. image upload/insert action;
7. autosave status;
8. `View Presentation`.

Metadata remains visible at the top of the page and may naturally scroll out of view.

Do not require collapsible metadata for MVP.

## F3.4 Metadata fields

At minimum support:

- title;
- start date;
- optional end date;
- subtitle/title-page secondary line;
- key photo.

Metadata is edited separately from page Markdown.

## F3.5 Key photo

A Memory requires a key photo before it is considered complete for normal Timeline presentation.

Default to the first successfully uploaded/used image when no key photo has been explicitly selected.

The author may change the key photo.

MVP may use the simplest UI consistent with this requirement.

## F3.6 Page strip

Display a lightweight horizontal page strip directly below metadata and above the editor.

Include:

- title-page representation;
- one thumbnail per authored page;
- Add Page affordance.

The strip may horizontally scroll when many pages exist.

The selected page is clearly indicated.

## F3.7 Thumbnail behavior

MVP thumbnails are lightweight representations.

They do not need to render exact miniature PRESENT pages.

They should communicate enough to identify:

- page order;
- selected page;
- approximate image/text presence.

Use pre-generated thumbnail assets when image display is needed.

## F3.8 Add Page

Adding a page creates a new authored Memory Page.

Its initial H2/page heading is blank.

Do not inject `Untitled`, today's date, or other guessed content.

## F3.9 Delete Page

MVP supports deleting authored Memory Pages.

Before deletion, show a simple confirmation.

Deleting a page removes that H2 section/content from the authoritative Memory document on successful persistence.

Deleting a page does not delete image files referenced by that page.

## F3.10 Reorder Page

MVP supports reordering authored pages.

Use explicit simple controls such as:

- Move Earlier;
- Move Later.

Drag-and-drop is deferred.

Reordering updates H2 section order in the authoritative Markdown.

## F3.11 Selected-page editor

Edit only one authored Memory Page at a time.

The user should not normally see/edit the entire Memory Markdown document.

The selected page editor contains the content inside the application-managed H2 boundary.

## F3.12 H2 restriction

H2 is reserved for application-managed page boundaries.

If the user enters a Markdown H2 inside the selected-page editor:

- do not silently split the page;
- show a clear warning;
- sanitize/remove/convert the invalid H2 according to the Markdown format implementation.

The user must use Add Page to create a new page.

## F3.13 Image upload/insertion

Keep MVP image authoring intentionally simple.

Do not provide a persistent image-library/gallery panel.

Provide an upload action associated with the selected page editor.

Expected interaction:

1. user invokes image upload from the selected page editor;
2. selects JPEG/JPG or HEIC;
3. UI indicates processing;
4. server stores/processes image;
5. on success, Markdown image reference is appended to the page Markdown.

The control label should make insertion behavior understandable, e.g.:

> Add picture to page Markdown

Exact wording may be refined in implementation.

## F3.14 Reusing existing uploaded images

MVP does not require an asset browser.

If the author needs to reference an already-uploaded image again, manually reusing/inserting the Markdown reference is acceptable for MVP.

A future image library may improve this workflow.

## F3.15 No image deletion

EDIT provides no per-image delete action.

Unused assets may accumulate.

## F3.16 Autosave

Autosave occurs in the background while changes exist.

Requirements:

- persist at least once per minute;
- may debounce/save sooner;
- changing pages should persist pending changes;
- autosave does not navigate away;
- use subtle `Saving…` / `Saved` state.

Do not rely on a routine manual Save button.

## F3.17 External modification conflict

EDIT must protect manually modified Markdown from being overwritten by a stale browser editor.

When EDIT loads, retain a source version/fingerprint.

Before autosave, verify the authoritative source has not changed externally.

If it changed:

- reject the autosave;
- do not overwrite `memory.md`;
- display a clear message such as:

> Memory changed outside the editor. Reload before continuing.

Keep this behavior simple.

MVP does not require merge/conflict-resolution UI.

## F3.18 View Presentation

Provide explicit:

> View Presentation

Before navigating, persist pending valid changes.

Then navigate to PRESENT for the Memory.

Autosave alone never automatically enters PRESENT.

---

# F4 — Markdown Persistence and Reconciliation

## F4.1 Purpose

Maintain portable authoritative Memory files while providing an efficient SQLite application index.

## F4.2 Authoritative source

`memory.md` is authoritative for:

- stable Memory ID;
- portable metadata;
- authored content;
- page order;
- image references.

SQLite mirrors/indexes metadata for application use.

## F4.3 Front matter

Use YAML front matter.

Required/expected fields include at least:

```yaml
id: 42
title: Taiwan 2026
start_date: 2026-02-03
end_date: 2026-02-17
key_photo: IMG_1234.jpg
subtitle: Taiwan and Hong Kong
```

Exact optionality/validation may be implemented according to Product Spec.

## F4.4 Body structure

Conceptual:

```markdown
# Taiwan 2026

Taiwan and Hong Kong

## February 4

![Taipei](IMG_1234.jpg)

- Arrived in Taipei

## February 5

...
```

H2 boundaries define authored pages.

The application may normalize formatting when serializing.

## F4.5 Normal write

For application-originated edits:

1. validate complete Memory state;
2. serialize complete Markdown;
3. write temporary file in same filesystem;
4. successfully close/flush;
5. atomically rename to `memory.md`;
6. update SQLite index;
7. report save success.

## F4.6 SQLite association

SQLite Memory records include:

- stable ID;
- source filename/path association;
- indexed metadata;
- source-change fingerprint/mtime information sufficient for cheap stale detection.

Do not match Memories solely by title.

## F4.7 External edit detection

When a Markdown source changes outside Rails, detect it using a simple deterministic source-change mechanism.

Expected dataset is only a few hundred Memories; avoid elaborate indexing infrastructure.

## F4.8 Reconciliation precedence

When valid Markdown metadata disagrees with SQLite:

> Markdown wins.

Overwrite/reindex SQLite from Markdown.

Log the reconciliation.

## F4.9 Matching order

Prefer:

1. YAML stable ID;
2. existing source path/filename association;
3. other unambiguous association evidence.

If identity is ambiguous, do not guess or merge based on title similarity.

Surface/log a manual-resolution condition.

## F4.10 External filename changes

If a user renames/moves a Markdown source outside the application, reconciliation may use stable ID to associate it with the existing SQLite Memory.

Update the SQLite source filename/path after an unambiguous stable-ID match.

If another SQLite record is already associated with the same source filename/path, report the conflict rather than silently overwriting unrelated identity.

## F4.11 Missing SQLite record

A valid Memory directory with valid YAML stable ID can be reindexed/imported into SQLite.

The system architecture must permit full SQLite Memory-index reconstruction from Memory directories.

## F4.12 Missing Markdown

If SQLite references missing Markdown:

- do not recreate it from stale SQLite automatically;
- log the problem;
- isolate the affected Memory;
- surface an actionable error when opened.

## F4.13 Invalid Markdown/YAML

Do not overwrite valid SQLite/file content based on unparseable external input.

Log parsing details sufficient for repair.

One invalid Memory must not take down unrelated Memories.

## F4.14 Autosave conflict protection

Autosave must compare the editor's loaded source version against current source state.

External changes after editor load cause autosave rejection.

Do not automatically apply the normal Markdown-wins reconciliation and then overwrite it with stale editor state.

The user reloads EDIT to receive the external version.

---

# F5 — Image Upload and Processing

## F5.1 Purpose

Accept scrapbook photographs during EDIT and pre-generate bandwidth-efficient presentation assets so PRESENT remains lightweight on the Raspberry Pi.

## F5.2 Accepted MVP formats

Accept:

- `.jpg`;
- `.jpeg`;
- `.heic` / `.HEIC` when libheif can decode the source.

Unsupported formats should produce a clear validation error.

## F5.3 Original preservation

Never silently replace an existing original.

JPEG:

```text
IMG_1234.jpg
IMG_1234_present.jpg
IMG_1234_thumb.jpg
```

HEIC:

```text
IMG_5678.HEIC
IMG_5678.jpg
IMG_5678_present.jpg
IMG_5678_thumb.jpg
```

Preserve HEIC original after conversion.

## F5.4 Filename collisions

Preserve original filename when safe.

If the filename exists, suffix deterministically:

```text
IMG_1234.jpg
IMG_1234_2.jpg
IMG_1234_3.jpg
```

Generate derivative names from the resolved collision-safe base.

Never overwrite.

## F5.5 Processing sequence

Synchronous upload flow:

```text
receive upload
   |
   v
validate
   |
   v
resolve safe non-colliding filename
   |
   v
store original
   |
   +-- HEIC --> JPEG normalized master
   |
   v
generate _present
   |
   v
generate _thumb
   |
   v
return asset reference
   |
   v
append Markdown to the page
```

## F5.6 HEIC normalization

Use libheif.

Generate normalized JPEG at approximately quality 90.

Correct orientation according to source metadata.

Preserve aspect ratio.

## F5.7 PRESENT derivative

Generate JPEG:

- quality approximately 90;
- maximum long edge 2560 px;
- preserve aspect ratio;
- do not upscale smaller source images merely to reach 2560 px.

## F5.8 Thumbnail derivative

Generate a small `_thumb.jpg` derivative during upload.

Exact maximum pixel dimensions are implementation-tunable based on final Timeline thumbnail size.

Requirements:

- substantially smaller than PRESENT derivative;
- sufficient visual quality for recognition;
- preserve aspect ratio;
- no runtime generation on Timeline GET.

## F5.9 Processing UI

While synchronous conversion/resizing occurs, EDIT shows an obvious but unobtrusive state such as:

> Processing…

The user should understand that the application is working rather than frozen.

Prevent accidental duplicate submission through the same upload control while that upload is processing.

## F5.10 Successful upload

Only after required processing succeeds:

- return success to EDIT;
- append the Markdown reference to the page Markdown;
- allow the uploaded image to become/default as key photo when applicable.

## F5.11 Processing failure

If libheif or another processing stage fails:

- show a clear error;
- include the relevant safe/useful libheif error message when it helps diagnose the problem;
- do not insert a broken Markdown reference;
- leave existing editor content unchanged;
- log detailed server-side diagnostic information.

Do not expose sensitive arbitrary server paths unnecessarily in browser error output.

## F5.12 GET behavior

No image transformation occurs during:

- TIMELINE GET;
- PRESENT GET;
- EDIT GET.

These surfaces consume pre-generated derivatives.

## F5.13 Asset deletion

MVP does not delete image assets through the UI.

A future maintenance feature may identify used/unused assets and provide safe cleanup.

---

# F6 — Appearance Preference

## F6.1 Default

Dark mode is the application default.

## F6.2 Control

Provide Dark/Light control at the bottom of TIMELINE.

## F6.3 Persistence

Persist the selected theme in the browser.

No user account is required.

## F6.4 EDIT

EDIT must support dark appearance as a first-class/default state.

## F6.5 PRESENT

PRESENT surroundings default dark.

The Memory presentation should remain visually coherent regardless of the TIMELINE/EDIT preference implementation.

---

# F7 — Application Access and Deployment Behavior

## F7.1 Supported access paths

The same Rails application supports:

```text
LAN:
http://192.168.12.111:8086

External:
Cloudflare -> cloudflared -> Rails :8086
```

## F7.2 Authentication

No Rails User/account/login system in MVP.

External access is protected by the Cloudflare boundary.

LAN access is trusted according to deployment/network policy.

## F7.3 Host independence

Core application behavior must not depend on Cloudflare-only headers.

The application must remain usable directly over the LAN.

---

# F8 — Error and Recovery Behavior

## F8.1 Philosophy

Prefer explicit, recoverable failures over silent guessing.

## F8.2 Autosave

If persistence fails:

- show error state;
- do not show `Saved`;
- preserve the previous valid authoritative Markdown file where possible.

## F8.3 Markdown write ordering

Write Markdown safely before updating SQLite.

If Markdown succeeds and SQLite fails, future reconciliation restores SQLite from Markdown.

## F8.4 Corrupt Memory

One corrupt Memory should not prevent unrelated Memories from working.

## F8.5 External editor conflict

Never overwrite an externally changed Memory with stale browser EDIT content.

Require reload.

## F8.6 Image failure

Do not mutate page Markdown to reference an image whose required processing failed.

---

# 9. Deferred Feature Specifications

The following are intentionally outside MVP and require separate future specifications:

- SHARE page;
- secret/unguessable share URL;
- QR-code sharing;
- revoke/regenerate share links;
- image-library browser;
- server-directory image browser;
- unused-image maintenance;
- bulk `Delete unused`;
- Memory deletion/recovery;
- image deletion/recovery;
- selectable page templates;
- three-image layouts;
- arbitrary image compositions;
- exact/live PRESENT thumbnails inside EDIT;
- drag-and-drop page reordering;
- advanced Timeline label collision detection;
- search;
- places/maps;
- people;
- statistics;
- PowerPoint import;
- automated backup;
- application-level users/roles.

Future layout work should assume an extensible selector/preview model rather than requiring changes to the core Memory/Page identity model.

---

# 10. Feature Dependency Map

```text
F4 Markdown Persistence & Reconciliation
        ^
        |
        +-------------------+
        |                   |
F3 Memory Editor       F1 Timeline
        |                   |
        |                   |
        +----> F5 Images    |
        |                   |
        +-------------------+
                 |
                 v
        F2 Memory Presentation

F6 Appearance
    -> Timeline / Edit / Present

F7 Access
    -> entire Rails application

F8 Error/Recovery
    -> persistence / editor / images / timeline
```

Implementation should establish F4/F5 persistence contracts before relying on them heavily from EDIT/PRESENT.

---

# 11. MVP End-to-End Feature Flow

A successful basic workflow is:

```text
empty TIMELINE
   |
   v
Add Memory
   |
   v
EDIT
   |
   +-- enter metadata
   |
   +-- upload JPEG/HEIC
   |      |
   |      +-- preserve original
   |      +-- normalize if required
   |      +-- generate PRESENT derivative
   |      +-- generate thumbnail
   |      +-- append Markdown to the page
   |
   +-- add/reorder/delete authored pages
   |
   +-- background autosave
   |      |
   |      +-- atomic memory.md write
   |      +-- SQLite index update
   |
   v
View Presentation
   |
   v
PRESENT
   |
   +-- title page
   +-- landscape Memory Pages
   +-- swipe/arrows/h-l
   +-- end state
   |
   v
Back to Timeline
   |
   v
Memory appears at proportional date position
```

This flow is the minimum integrated feature set that constitutes a useful MVP.
