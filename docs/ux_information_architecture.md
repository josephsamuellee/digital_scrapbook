# UX / Information Architecture

## 1. Purpose

This document defines the user-experience structure and information architecture for the MVP described in `product_spec.md`.

It is intended to be implementation-independent and AI-agent-ready. It defines:

- the application’s top-level destinations;
- how users move between those destinations;
- the information hierarchy within each destination;
- responsive and orientation behavior;
- authoring behavior at the UX level;
- empty and important system states;
- UX constraints that later wireframes and feature specifications must preserve.

This document does **not** define exact pixel dimensions, CSS, Rails routes/controllers, database schema, Markdown parser implementation, image-processing implementation, or detailed acceptance tests.

When a later implementation choice conflicts with this document, preserve the user-facing behavior defined here unless a newer product/UX specification explicitly supersedes it.

---

## 2. Core UX Principles

### 2.1 Timeline-first retrieval

The homepage is a chronological Timeline, not an album grid, folder browser, photo gallery, or search-first interface.

The Timeline exists to make Memories recognizable and retrievable without requiring the user to remember filenames or open individual presentation files.

### 2.2 Memory is the primary content object

A `Memory` is the primary user-facing object.

A Memory contains:

- structured metadata;
- one automatically generated title page;
- zero or more authored Memory Pages;
- associated image assets.

A `Memory Page` is one landscape presentation viewport within a Memory.

### 2.3 Presentation and authoring are separate modes

The product has distinct modes:

- **TIMELINE** — browse and retrieve Memories;
- **PRESENT** — display one Memory Page at a time;
- **EDIT** — create or modify a Memory.

PRESENT should feel like viewing a lightweight scrapbook presentation, not editing a webpage.

EDIT should optimize for simple authoring rather than exposing storage implementation details.

### 2.4 Mobile-first presentation

PRESENT is designed first for a phone held in landscape orientation.

The Timeline remains usable in portrait or landscape.

EDIT may be responsive but is primarily expected to be used from a conventional desktop/laptop browser.

### 2.5 Timeline is responsive; Memory Pages are scaled

This distinction is a core UX rule:

> Timeline layouts may adapt to available viewport dimensions. Authored Memory Pages do not reflow into fundamentally different compositions; they remain landscape pages and are proportionally scaled to fit the available presentation viewport.

Desktop PRESENT therefore displays a centered landscape presentation canvas rather than rearranging scrapbook content according to browser width.

### 2.6 Dark by default

The application's default appearance is dark.

The user may switch to light mode. The selected preference persists in the browser.

PRESENT defaults to dark presentation surroundings.

### 2.7 Low interface chrome

The application should avoid persistent navigation that competes with the Memories.

TIMELINE and EDIT may have minimal page-level headers.

PRESENT has no persistent global application header.

### 2.8 Portable content should not dictate awkward authoring UX

Each Memory is stored as a single Markdown-backed document, but EDIT does not need to expose that document as one large raw Markdown file.

The editor presents Memory Pages individually while maintaining the underlying page boundaries for the user.

---

## 3. Top-Level Information Architecture

MVP has three user-facing destinations:

```text
TIMELINE
   |
   +-- select Memory -----------------> PRESENT
   |
   +-- Add Memory --------------------> EDIT
                                          |
                                          +-- View Presentation --> PRESENT
                                                                     |
                                                                     +-- End
                                                                          |
                                                                          +-- Back to Timeline
                                                                          |
                                                                          +-- Edit Memory --> EDIT
```

There are no additional top-level MVP destinations.

Specifically, MVP does not require:

- Settings page;
- account/profile page;
- standalone image/file manager;
- maintenance page;
- search page;
- location/map page;
- comments/activity page;
- sharing page.

A future **SHARE** destination should remain architecturally possible. It may eventually expose an unguessable share URL and QR code, but it must not appear as a disabled or “coming soon” control in MVP.

A future maintenance capability may inspect used versus unused Memory assets and perform bulk cleanup. MVP intentionally provides no image-deletion workflow.

---

## 4. Global Navigation Model

### 4.1 TIMELINE

TIMELINE is the application homepage and primary navigation surface.

Selecting a Memory navigates directly to that Memory in PRESENT.

The action for creating a Memory is deliberately not emphasized at the top of the Timeline. `Add Memory` is located after the oldest rendered year, at the bottom of the page.

### 4.2 PRESENT

PRESENT removes normal application chrome and prioritizes the current Memory Page.

Navigation occurs through presentation controls and supported gestures/keyboard inputs.

The generated end state provides navigation back to TIMELINE or into EDIT.

### 4.3 EDIT

EDIT is used for both creation and modification.

Creation and editing are one conceptual interface:

- New Memory begins with empty/default metadata and content.
- Existing Memory begins with persisted metadata, pages, and assets.

The user explicitly selects `View Presentation` to leave authoring and inspect PRESENT.

Autosave does not automatically navigate away from EDIT.

---

## 5. TIMELINE Information Architecture

### 5.1 Page identity

The Timeline page title is:

> **Our Memories**

The title should be visible but should not consume enough vertical space to materially reduce the number of years visible.

### 5.2 Information hierarchy

The Timeline is organized as:

```text
Our Memories

[most recent year]
    proportional timeline
    Memory items

[next year]
    proportional timeline
    Memory items

...

[oldest year]
    proportional timeline
    Memory items

+ Add Memory

Appearance: Dark / Light
```

Years are reverse chronological.

Only years containing at least one Memory are rendered.

If the current year contains no Memory, the current year is not rendered merely because it is the current year.

### 5.3 Year timeline

Each year is represented by one horizontal Jan 1 → Dec 31 time axis.

The entire year should fit within the available Timeline width without horizontal scrolling.

Memory start/end positions are proportional to their dates within the year.

Quarter markers are sufficient. Month markers are not required.

The visual design should avoid excessive labels and grid decoration.

### 5.4 Memory duration segment

A Memory with a date range is represented by a segment whose start and end correspond to its actual dates.

A single-day Memory is valid and may collapse to an appropriately visible point/short marker.

All Memory duration segments for a year should preferably occupy the same primary horizontal axis rather than assigning every overlapping Memory its own timeline lane.

MVP does not require sophisticated collision detection for labels.

Future collision handling should preserve true date positions and may stagger labels vertically rather than shifting Memory dates.

When multiple Memories overlap, the earlier-starting Memory should visually retain the higher/earlier label position when practical.

### 5.5 Memory label

Each Timeline Memory item should remain visually sparse.

MVP label information:

- key photo;
- Memory title.

Do **not** add exact textual dates, summaries, locations, page counts, or other metadata to the normal Timeline item during MVP.

The timeline itself communicates approximate timing and duration.

### 5.6 Interaction target

The duration marker, connector/label region, key photo, and title conceptually belong to one Memory interaction target.

The UI should provide a sufficiently large touch target even when the visible timeline segment is small.

Selecting the item navigates to PRESENT for that Memory.

### 5.7 Portrait behavior

TIMELINE must remain usable on a phone in portrait orientation.

It should compress/reflow its Timeline presentation to the available width rather than requiring device rotation and rather than introducing horizontal scrolling.

Landscape remains the preferred view for seeing chronological spacing clearly.

### 5.8 Vertical density

The design should favor compact year sections.

On a typical phone in landscape orientation, vertical density should target visibility of at least two complete years when Memory density permits.

The exact geometry belongs in annotated wireframes.

### 5.9 Bottom controls

Administrative/system controls belong at the bottom of the Timeline, after the oldest year:

1. `Add Memory`
2. `Continue Draft`, when at least one incomplete draft exists
3. appearance/theme control

The appearance preference persists locally in the browser.

Dark is the default when no preference has previously been saved.

### 5.10 Empty state

An empty application renders no artificial year.

Conceptually:

```text
Our Memories

No memories yet.

+ Add Memory

Appearance: Dark / Light
```

The empty state should make creation discoverable without introducing a separate onboarding workflow.

---

## 6. PRESENT Information Architecture

### 6.1 Purpose

PRESENT is optimized for an owner/author physically clicking or swiping through a Memory while showing it to another person.

It is not a scrolling article, photo gallery, or editing interface.

### 6.2 Presentation unit

Exactly one Memory Page is presented at a time.

The user does not vertically scroll between authored Memory Pages.

### 6.3 Landscape canvas

Every Memory Page uses a landscape presentation canvas.

On desktop/tablet, the landscape canvas is proportionally scaled and centered within the browser viewport.

Do not fundamentally reflow the authored page based on desktop window dimensions.

Surrounding unused viewport space uses the presentation theme, dark by default.

### 6.4 Phone portrait state

When PRESENT is opened on a phone in portrait orientation, the application should not attempt to redesign the page into portrait.

Instead, display a lightweight overlay instructing the user to rotate the device.

After rotation to landscape, the Memory Page becomes available.

### 6.5 Title page

Every Memory begins with a generated title page.

The title page is derived from structured Memory metadata and is not treated as a normal authored Markdown page.

Initial hierarchy:

- centered H1-equivalent Memory title;
- centered one-line H2-equivalent subtitle/date text beneath it.

The title-page metadata is editable from EDIT.

### 6.6 Authored page layout

MVP supports up to:

- three images per Memory Page;
- three text blocks per Memory Page.

The default MVP presentation template prioritizes one image plus accompanying text.

For the common one-image page, approximately 70–80% of the landscape width should be available to the image region, with the remaining region used for Markdown text/bullets.

Exact layout rules belong in annotated wireframes and feature specifications.

MVP does not require user-selectable templates.

Future templates may accommodate portrait/landscape photographs and varying source aspect ratios.

### 6.7 Text behavior

Markdown text is supported.

The normal authoring expectation is concise bullet-point reflection/content, while several paragraphs remain valid when needed to preserve the Memory.

PRESENT should render the authored text without exposing Markdown syntax.

### 6.8 Navigation inputs

MVP supports:

- visible Previous control;
- visible Next control;
- touch swipe left/right;
- keyboard Left Arrow / Right Arrow;
- keyboard `h` / `l`.

Controls should be subtle but always visible.

They should not depend on hover or tap-to-reveal behavior.

### 6.9 Page position

PRESENT displays current position within the Memory, for example:

```text
4 / 17
```

The exact placement belongs in wireframes.

The current authored page heading does not need a separate global navigation label if it is already part of the Memory Page content.

### 6.10 End state

After the final authored Memory Page, PRESENT shows a generated end state rather than leaving the user at an ambiguous dead end.

It provides:

- `Back to Timeline`
- `Edit Memory`

Navigating backward/swiping back from the end state returns to the final authored Memory Page.

The end state is system UI and is not persisted as an authored Memory Page.

### 6.11 No global header

PRESENT has no persistent global application header.

Administrative actions are intentionally deferred until the generated end state.

---

## 7. EDIT Information Architecture

### 7.1 Purpose

EDIT allows the author to create and maintain a Memory while preserving the simplicity of one Markdown-backed Memory document.

The interface should feel page-oriented, not like editing a large source file.

### 7.2 Overall hierarchy

Conceptually:

```text
Edit Memory

[Metadata]

[Memory Page Strip / Thumbnails]

[Selected Page Editor]

[Pictures / Upload]

[Autosave status]

[View Presentation]
```

The screen may vertically scroll.

Tabs are not required for MVP.

### 7.3 Metadata section

Structured metadata appears independently at the top of EDIT.

At minimum it includes:

- Memory title;
- start date;
- optional end date;
- title-page subtitle/date display content as applicable;
- key photo selection.

The metadata section is not part of the selected page's Markdown editor.

The title page is represented separately from normal authored Memory Pages.

### 7.4 Page strip

EDIT includes a horizontally navigable strip/list of page thumbnails.

It contains:

- title-page thumbnail;
- one thumbnail for each authored Memory Page;
- affordance to add a Memory Page.

Selecting a thumbnail changes the active page in the editor.

The page strip exists to make a 1–20 page Memory easy to understand and navigate during authoring.

### 7.5 Thumbnail complexity

MVP thumbnails are lightweight representations, not required to be exact scaled screenshots of PRESENT.

They should provide enough information to recognize:

- page order;
- approximate image presence/composition;
- approximate text presence;
- selected page.

This avoids unnecessary presentation rendering work while editing.

### 7.6 Page operations

MVP supports:

- add page;
- delete page;
- reorder page.

MVP does not require drag-and-drop.

Reordering may use explicit controls such as Move Earlier / Move Later or equivalent directional actions.

Drag-and-drop may be added later.

### 7.7 Selected-page Markdown editor

Only one authored Memory Page is edited at a time.

The editor exposes the Markdown content belonging to that page, rather than the complete Memory Markdown file.

The application owns page boundaries.

### 7.8 H2/page-boundary rule

In persistent Markdown, H2 boundaries (`##`) identify authored Memory Pages.

However, users do not manually manage these boundaries from the per-page editor.

The application creates, removes, and reorders the corresponding boundaries when pages are manipulated through EDIT.

An H2 entered inside a page editor is invalid because it would conflict with the page abstraction.

The editor should prevent or sanitize such headings and provide a clear inline/non-destructive warning, for example:

> Level-2 headings define Memory Pages and are not allowed inside a page. This heading will be removed or converted when saved.

The precise sanitization behavior belongs in the Markdown feature specification.

The UX should not silently create an unexpected new page merely because the user typed `##` inside the page editor.

### 7.9 Other Markdown headings

Whether H1 or deeper headings are permitted inside authored pages should be specified later by the Markdown feature specification.

The editor must reserve H2 for application-managed page boundaries.

### 7.10 Image area

EDIT contains an image area for assets belonging to the current Memory.

Uploaded assets remain visible even when they are not currently referenced by a Memory Page.

MVP intentionally permits unused assets to accumulate.

Do not provide per-image deletion controls in MVP.

Future maintenance functionality may identify:

- used assets;
- unused assets;
- bulk deletion candidates.

### 7.11 Upload and insertion

EDIT allows image upload.

The image action should make its insertion behavior explicit, e.g.:

> **Add picture to page Markdown**

The interaction:

1. user chooses/uploads an image from the selected page editor;
2. upload is persisted;
3. derivative generation occurs;
4. an appropriate Markdown image reference is appended to the page Markdown.

The exact Markdown path/reference syntax is not an IA concern.

### 7.12 Existing Memory assets

The image area should show images already uploaded for the Memory so that the author can reuse them while constructing pages.

MVP does not require browsing arbitrary server directories or integrating with another gallery application.

### 7.13 Key photo

Every Memory requires a key photo.

The first uploaded/used image may become the default key photo.

EDIT allows the author to change the key photo.

The exact portable metadata representation used to mark the key photo is an Architecture/Feature Specification decision; the UX only requires that key-photo selection be obvious and efficient.

### 7.14 Autosave

EDIT uses background autosave.

Requirements at the UX level:

- changes are persisted automatically no less frequently than once per minute while there are unsaved changes;
- switching between Memory Pages should persist the current page before or as part of the transition;
- autosave does not navigate the user away from EDIT;
- the interface should provide a subtle state such as `Saving…` and `Saved`;
- the author should not need a routine manual Save button.

Because autosave is expected, MVP does not rely on a browser “unsaved changes” warning as the normal protection mechanism.

Exact debouncing, conflict handling, and persistence implementation belong in later specifications.

### 7.15 View Presentation

EDIT provides an explicit `View Presentation` action.

Selecting it persists pending changes as needed and navigates to PRESENT for the current Memory.

This is the author's primary validation/preview workflow.

There is no Draft/Publish distinction in MVP.

---

## 8. Theme and Appearance

### 8.1 Default

Dark mode is the default application theme.

This applies to TIMELINE and EDIT when no stored preference exists.

PRESENT uses dark surroundings by default.

### 8.2 Toggle location

The global Dark/Light appearance control appears at the bottom of TIMELINE after `Add Memory`.

It should not occupy persistent high-priority navigation space.

### 8.3 Persistence

Theme preference persists in the browser across sessions.

### 8.4 EDIT support

EDIT must be usable in dark mode.

Light mode should not be treated as the only or primary authoring appearance.

---

## 9. Responsive Behavior Summary

| Surface | Phone Portrait | Phone Landscape | Desktop / Large Browser |
|---|---|---|---|
| TIMELINE | Supported; compressed responsive timeline | Preferred; accurate landscape timeline | Supported; responsive timeline |
| PRESENT | Rotation overlay | Primary presentation experience | Fixed landscape canvas scaled to fit |
| EDIT | Functional where practical, not primary authoring target | Functional where practical | Primary authoring experience |

TIMELINE must not require horizontal scrolling to represent one year.

PRESENT Memory Pages should scale rather than fundamentally reflow.

---

## 10. Important MVP States

### 10.1 Empty application

TIMELINE shows:

- `Our Memories`;
- empty-state message;
- `Add Memory`;
- theme control.

No empty year axes are generated.

### 10.2 Memory with one day

A Memory may have the same start/end date or no separate end date.

TIMELINE must still provide a visible, tappable marker.

### 10.3 Memory spanning multiple years

The Memory remains one object.

Its Timeline representation may appear in both relevant year timelines according to Product Spec rules.

Selecting either representation opens the same Memory.

### 10.4 Memory with unused images

Unused images remain associated with the Memory and remain available in EDIT.

No cleanup warning is required in MVP.

### 10.5 Invalid H2 in page editor

The user receives a clear warning that H2 is reserved for application-managed page boundaries.

The application must not unexpectedly split the page without explicit page-level user action.

### 10.6 Saving state

Autosave feedback is subtle and non-blocking.

Editing should not be interrupted by routine persistence.

### 10.7 PRESENT in wrong orientation

On a phone in portrait orientation, PRESENT displays a rotate-device overlay rather than a portrait reflow of the Memory Page.

### 10.8 Incomplete draft

Incomplete Memories do not appear as normal Timeline entries.

When at least one exists, Timeline offers `Continue Draft` after the oldest year, next to `Add Memory`.

`Add Memory` warns that an unfinished Memory exists and offers Continue Draft or Create Another.

---

## 11. Deferred UX Capabilities

The IA should not block the following future additions, but they are not MVP requirements:

### 11.1 SHARE

A future SHARE destination may be reachable from EDIT and/or the PRESENT end state.

Likely responsibilities:

- generate/display an unguessable Memory URL;
- copy share URL;
- display QR code for quick in-person sharing;
- revoke/regenerate a secret URL.

MVP should not expose inactive SHARE controls.

### 11.2 Asset maintenance

A future maintenance surface may identify used and unused images and provide safe cleanup, potentially including a `Delete all unused` workflow.

MVP does not delete uploaded image assets through the UI.

### 11.3 Richer page templates

Future authoring may support selectable presentation templates for:

- portrait photographs;
- landscape photographs;
- multiple image arrangements;
- varying source aspect ratios.

MVP uses a simple default layout.

### 11.4 Exact page thumbnails/live preview

A future EDIT page strip may render exact miniature PRESENT views.

MVP uses lightweight thumbnails.

### 11.5 Drag-and-drop

Future EDIT may support drag-and-drop page reordering and richer asset manipulation.

MVP may use explicit reorder controls.

### 11.6 Collision-aware Timeline labels

Future Timeline rendering may calculate label collisions and automatically stagger labels while preserving actual Memory dates.

MVP may use simpler deterministic positioning.

### 11.7 Server asset browsing

Future EDIT may allow the user to browse approved server directories and explicitly select existing images.

MVP requires direct upload only.

---

## 12. UX Non-Goals

MVP UX must not evolve into:

- a conventional photo gallery;
- a social feed;
- a collaborative editor;
- a commenting/reaction system;
- a travel-planning interface;
- a map/location browser;
- a file-manager-first interface;
- a PowerPoint clone;
- a native mobile application;
- an infinite-scroll presentation;
- a video presentation system.

The primary experience remains:

> **find a Memory chronologically → present it page by page → edit it simply when needed.**

---

## 13. Requirements for Annotated Wireframes

The next design artifact should convert this IA into annotated wireframes for at least:

1. TIMELINE — phone landscape;
2. TIMELINE — phone portrait;
3. TIMELINE — desktop;
4. TIMELINE — empty state;
5. PRESENT — generated title page;
6. PRESENT — standard one-image + text Memory Page;
7. PRESENT — desktop scaled landscape canvas;
8. PRESENT — phone portrait rotation overlay;
9. PRESENT — generated end state;
10. EDIT — desktop overview;
11. EDIT — metadata section;
12. EDIT — page thumbnail strip and page operations;
13. EDIT — selected-page Markdown editor;
14. EDIT — image upload/insertion area;
15. EDIT — autosave states.

Wireframes should specify geometry and interaction targets without prematurely defining implementation details.

Particular attention should be paid to:

- year timeline proportions;
- quarter markers;
- Memory duration segments;
- key-photo/title label placement;
- vertical density sufficient to show approximately two years on a landscape phone when feasible;
- fixed landscape PRESENT aspect/canvas;
- the default one-image + text composition;
- Previous/Next controls and page-position indicator;
- page-thumbnail navigation in EDIT;
- the bottom-of-Timeline placement of creation and appearance controls.

---

## 14. UX Decision Summary

The following decisions are authoritative for MVP unless explicitly superseded:

- Homepage is TIMELINE.
- Page title is `Our Memories`.
- Timeline years are reverse chronological and only exist when Memories exist.
- Each year fits horizontally without scrolling.
- Memory dates determine proportional Timeline placement.
- Quarter markers are sufficient.
- Timeline labels show key photo + title, not exact dates.
- Timeline is responsive in portrait and landscape.
- `Add Memory` and theme controls live at the bottom of TIMELINE.
- Dark mode is the default and persists.
- PRESENT shows exactly one landscape Memory Page at a time.
- PRESENT does not vertically scroll between Memory Pages.
- PRESENT supports visible controls, swipe, arrow keys, and `h`/`l`.
- PRESENT exposes page position.
- Phone portrait PRESENT requests rotation.
- Desktop PRESENT scales a fixed landscape canvas rather than reflowing it.
- PRESENT has no persistent global header.
- A generated end state links to TIMELINE and EDIT.
- CREATE and EDIT use the same authoring interface.
- Metadata is separate from page Markdown.
- EDIT operates on one Memory Page at a time.
- A lightweight page-thumbnail strip provides page navigation.
- MVP supports add/delete/reorder page operations.
- H2 Markdown boundaries are application-managed.
- Uploaded images may remain unused indefinitely in MVP.
- MVP provides no image deletion workflow.
- Image upload can append a Markdown reference to the selected page.
- Key photo is required and editable.
- EDIT autosaves in the background at least once per minute when changes exist.
- `View Presentation` explicitly transitions from EDIT to PRESENT.
- SHARE, asset maintenance, exact live thumbnails, templates, and drag-and-drop are deferred.
