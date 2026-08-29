# Annotated Wireframes — MVP

## 1. Purpose

This document translates `product_spec.md` and `ux_information_architecture.md` into implementation-oriented screen layouts and interaction geometry.

It defines approximate placement, hierarchy, responsive behavior, interaction targets, and important screen states. It intentionally does **not** prescribe exact CSS values, fonts, Rails implementation, database design, or final visual polish.

Where ratios are approximate, implementation should preserve the stated intent and allow later UX tuning without changing the underlying information architecture.

---

## 2. Global Visual Rules

- Dark mode is the default.
- Layout is primarily flat, low-decoration, and photograph-focused.
- Avoid unnecessary cards, shadows, gradients, decorative animation, or page-flip effects.
- No horizontal scrolling for a one-year Timeline.
- PRESENT uses a landscape composition and never changes source-image aspect ratio.
- Timeline is responsive; PRESENT compositions scale rather than fundamentally reflow.
- Touch targets may be larger than their visible markers.
- Exact spacing may be tuned after implementation; preserve the relative hierarchy below.

---

# 3. TIMELINE

## 3.1 Phone Landscape — Primary Timeline View

Target: iPhone-class landscape viewport, approximately 19.5:9. Exact viewport ratio is not canonical.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Our Memories                                                               │
│                                                                            │
│ 2026 ─────────────────┬─────────────────┬─────────────────┬─────────────── │
│                       Q2                Q3                Q4                │
│        ●────────●                                                           │
│             │                                                               │
│             └── [img] Taiwan 2026                                           │
│                            ●──────────────────●                              │
│                                      │                                      │
│                                      └── [img] Summer Trip                  │
│                                                                            │
│ 2025 ─────────────────┬─────────────────┬─────────────────┬─────────────── │
│                       Q2                Q3                Q4                │
│    ●                                                                       │
│    │                                                                       │
│    └── [img] Christmas                                                     │
│                                              ●──────●                       │
│                                                  │                         │
│                                                  └── [img] Boston           │
│                                                                            │
│ ...                                                                        │
│                                                                            │
│                              + Add Memory                                  │
│                              Appearance: Dark / Light                       │
└────────────────────────────────────────────────────────────────────────────┘
```

### Annotations

1. **Our Memories** is the only prominent page title.
2. Years are reverse chronological and rendered only when at least one Memory intersects that year.
3. Each year uses one Jan 1 → Dec 31 horizontal timeline.
4. Q2/Q3/Q4 markers divide the line quietly. Q1 is implied by the beginning of the year and year label.
5. Multi-day Memory segment position and length are proportional to dates across the year.
6. A Memory label connects approximately from the midpoint of its duration segment.
7. Label is compact: a thumbnail approximately 2–3 lines of text tall, followed by the Memory title.
8. Exact textual dates are omitted from Timeline labels in MVP.
9. Whole Memory representation is one interaction target: visible segment, connector, thumbnail, and title all navigate to PRESENT.
10. Invisible touch target should be larger than thin visible timeline geometry.
11. Labels may stagger vertically. Sophisticated collision detection is deferred.
12. Prefer all duration segments on the same primary horizontal timeline when possible.
13. Vertical density should make roughly two complete years visible in landscape when Memory density permits.
14. `Add Memory` and appearance configuration occur only after the oldest rendered year.

### Timeline geometry

For multi-day Memories, the important relationship is proportional placement:

```text
x(date) ≈ available_year_width × calendar_position_within_year
```

Exact implementation formula belongs in Architecture/Feature Specification. The visual result must preserve relative calendar placement and duration.

A multi-day Memory should not receive an arbitrary minimum duration that materially misrepresents its length.

---

## 3.2 Single-Day / Very Short Memory

```text
2026 ────────────────┬─────────────────┬─────────────────┬──────────────
                     Q2                Q3                Q4

                         ●
                         │
                         └── [img] Birthday
```

### Annotations

1. A single-day Memory uses a visible circle/point rather than a zero-width line.
2. The point may be visually larger than quarter-divider marks.
3. Very short Memories may use a minimum visible marker size for usability.
4. This minimum marker is a visual affordance only; the underlying date remains exact.

---

## 3.3 Overlapping Memories

MVP may use simple deterministic label staggering.

```text
2026 ────────────────┬─────────────────┬─────────────────┬──────────────
                     Q2                Q3                Q4

        ●────●
           │
           └── [img] Memory A
          ●──────────────●
                 │
                 └────────── [img] Memory B
```

### Annotations

1. Do not move the actual timeline segment to a false date to avoid collision.
2. Earlier-starting Memory should receive the upper/earlier label position when practical.
3. Future collision detection may calculate label lanes automatically.
4. MVP may tolerate imperfect label placement when unusually dense data occurs.

---

## 3.4 Phone Portrait Timeline

```text
┌──────────────────────────────────────┐
│ Our Memories                         │
│                                      │
│ 2026 ──────┬──────┬──────┬──────── │
│            Q2     Q3     Q4          │
│    ●──●                              │
│      └─ [i] Taiwan                   │
│                   ●────●             │
│                     └─ [i] Trip      │
│                                      │
│ 2025 ──────┬──────┬──────┬──────── │
│            Q2     Q3     Q4          │
│       ●                              │
│       └─ [i] Christmas               │
│                                      │
│          + Add Memory                │
│          Appearance: Dark / Light    │
└──────────────────────────────────────┘
```

### Annotations

1. Portrait Timeline remains functional; do not require rotation.
2. Compress timeline geometry to viewport width.
3. Do not introduce horizontal scrolling.
4. Thumbnail and label may become smaller than landscape but remain recognizable/tappable.
5. Preserve proportional date placement as far as available width permits.

---

## 3.5 Desktop Timeline

```text
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ Our Memories                                                                         │
│                                                                                      │
│ 2026 ───────────────────────┬──────────────────────┬──────────────────────┬──────── │
│                             Q2                     Q3                     Q4           │
│          ●──────●                                                                    │
│              │                                                                       │
│              └── [thumbnail] Taiwan 2026                                              │
│                                                     ●────────────●                    │
│                                                          │                           │
│                                                          └── [thumbnail] New England │
│                                                                                      │
│ 2025 ...                                                                             │
│                                                                                      │
│                                   + Add Memory                                       │
│                                   Appearance: Dark / Light                            │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

The year timeline expands with the available content width but still represents exactly one year without horizontal scrolling.

---

## 3.6 Empty Timeline

```text
┌──────────────────────────────────────────────────────────────┐
│ Our Memories                                                 │
│                                                              │
│                     No memories yet.                         │
│                                                              │
│                       + Add Memory                           │
│                                                              │
│                    Appearance: Dark / Light                  │
└──────────────────────────────────────────────────────────────┘
```

Do not render empty years.

---

# 4. PRESENT

## 4.1 General Presentation Canvas

PRESENT is designed primarily for an iPhone-class landscape viewport.

There is no canonical authored aspect ratio. The layout should use the available landscape viewport while preserving image aspect ratios and meaningful outer margins.

No persistent application header is shown.

---

## 4.2 Generated Title Page

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│                                                                            │
│                         TAIWAN 2026                                        │
│                                                                            │
│                    February 3–17, 2026                                     │
│                                                                            │
│                                                                            │
│                                                                            │
│  ‹                                                           ›             │
│                              1 / 17                                        │
└────────────────────────────────────────────────────────────────────────────┘
```

### Annotations

1. Memory title is centered and visually dominant.
2. One-line subtitle/date metadata appears centered beneath it.
3. Title page is generated from structured metadata and editable through EDIT metadata controls.
4. Navigation controls remain subtle and near the lower left/right edges rather than vertically centered.
5. Page position appears near bottom-center.

---

## 4.3 Default One-Landscape-Image Page

Approximate starting geometry only; tune after implementation.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│     ┌──────────────────────────────────────────┐   • First memory          │
│     │                                          │                           │
│     │                                          │   • Something funny       │
│     │              3:2 IMAGE                   │     happened here.        │
│     │        aspect ratio preserved            │                           │
│     │                                          │   • A few paragraphs      │
│     │                                          │     remain acceptable.    │
│     └──────────────────────────────────────────┘                           │
│                                                                            │
│  ‹                                                           ›             │
│                              4 / 17                                        │
└────────────────────────────────────────────────────────────────────────────┘
```

### Starting layout guidance

1. Do **not** stretch/crop source images merely to fill the presentation canvas.
2. Preserve the source image aspect ratio.
3. A common 3:2 landscape image should occupy roughly 80–90% of available vertical presentation height at most, leaving breathing room/navigation space.
4. Start with approximately 10% conceptual outer spacing at top/left/bottom where practical. These are UX tuning targets, not hard CSS requirements.
5. Maintain a clear middle gap between image and text.
6. Maintain right-side breathing room after text.
7. A typical 3:2 landscape photo may result in approximately 70/30 image/text horizontal allocation.
8. A 4:3 image may naturally leave more horizontal room for text, potentially closer to 60/40.
9. **Do not force fixed 70/30 or 60/40 ratios.** Image aspect ratio and target vertical size should drive its width; text uses the remaining safe horizontal region.
10. Do not enlarge an image until it fills the entire screen height.
11. Final geometry requires UX tuning after real photographs are rendered on target devices.

---

## 4.4 Portrait-Image Guidance

Portrait layouts are intentionally limited in MVP, but the wireframe should not encourage one narrow portrait image to waste the presentation canvas.

Preferred future/default direction when portrait assets are used:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│     ┌──────────────┐  ┌──────────────┐        • Commentary                 │
│     │              │  │              │                                     │
│     │  PORTRAIT    │  │  PORTRAIT    │        • Another point             │
│     │    IMAGE     │  │    IMAGE     │                                     │
│     │              │  │              │        • Reflection                │
│     └──────────────┘  └──────────────┘                                     │
│                                                                            │
│  ‹                                                           ›             │
│                              6 / 17                                        │
└────────────────────────────────────────────────────────────────────────────┘
```

MVP may initially support a simpler deterministic layout. Do not distort portrait images. More sophisticated templates are deferred.

---

## 4.5 Navigation Geometry

Visible controls should be located near the lower left and lower right portions of the screen.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│                         PRESENTATION CONTENT                               │
│                                                                            │
│                                                                            │
│                                                                            │
│   ‹                                                        ›               │
│                              4 / 17                                        │
└────────────────────────────────────────────────────────────────────────────┘
```

### Interaction rules

- Visible arrow/control activates Previous/Next.
- Swipe left/right activates Next/Previous as expected.
- Left/Right Arrow keys navigate.
- `h` / `l` navigate backward/forward.
- Do **not** make the entire left/right screen halves navigation targets.
- If larger invisible touch regions are needed, constrain them to approximately the outer 20% left/right regions and keep the central content area free from navigation tap behavior.
- Avoid interfering with future content interaction or text selection.
- No decorative transition animation is required.

---

## 4.6 Generated End State

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│                             Taiwan 2026                                    │
│                                                                            │
│                                  End                                       │
│                                                                            │
│                    [ Back to Timeline ]                                    │
│                    [ Edit Memory ]                                         │
│                                                                            │
│   ‹                                                                        │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

- Back/swipe returns to the final authored Memory Page.
- `Back to Timeline` returns home.
- `Edit Memory` opens EDIT.
- End state is generated system UI, not persisted as an authored page.

---

## 4.7 Phone Portrait Rotation Overlay

```text
┌──────────────────────────────┐
│                              │
│                              │
│       Rotate your phone      │
│       to view this Memory    │
│                              │
│             ↻                │
│                              │
│                              │
└──────────────────────────────┘
```

Do not portrait-reflow the scrapbook presentation.

---

## 4.8 Desktop PRESENT

```text
┌────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                    │
│        ┌──────────────────────────────────────────────────────────────────┐        │
│        │                                                                  │        │
│        │                 SCALED LANDSCAPE MEMORY PAGE                     │        │
│        │                                                                  │        │
│        │                                                                  │        │
│        │   ‹                                                   ›          │        │
│        │                            4 / 17                                │        │
│        └──────────────────────────────────────────────────────────────────┘        │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Scale and center the landscape presentation. Do not redesign/reflow it as a desktop document.

---

# 5. EDIT

## 5.1 Desktop Overview

EDIT is primarily desktop-oriented and may vertically scroll.

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ Edit Memory                                                                  │
│                                                                              │
│ MEMORY DETAILS                                                               │
│ Title       [ Taiwan 2026                                                  ] │
│ Start       [ 2026-02-03 ]     End [ 2026-02-17 ]                           │
│ Subtitle    [ February 3–17, 2026                                          ] │
│ Key photo   [ small thumbnail / selector ]                                  │
│                                                                              │
│ PAGES                                                                        │
│ [Title] [2] [3] [4] [5] [6] [7] ---------------------------> [+ Add Page]  │
│                 ▲                                                            │
│              selected                                                        │
│                                                                              │
│ PAGE 4                         [Move Earlier] [Move Later] [Delete Page]      │
│ ┌──────────────────────────────────────────────────────────────────────────┐ │
│ │ Markdown editor                                                        │ │
│ │                                                                        │ │
│ │ ![image](...)                                                          │ │
│ │                                                                        │ │
│ │ - We went to...                                                        │ │
│ │ - I remember...                                                        │ │
│ │                                                                        │ │
│ │ [cursor]                                                               │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│ [ Add Picture at Editor Cursor ]                                             │
│                                                                              │
│ Saved 8:42 PM                                      [ View Presentation ]     │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Annotations

1. Metadata remains visible at the top and is not collapsible in MVP.
2. User may simply scroll past metadata when focusing on page editing.
3. Page strip appears directly below metadata and above the editor.
4. Page strip horizontally scrolls when the Memory has more pages than fit.
5. The first item represents the generated title page.
6. Lightweight thumbnails are sufficient; do not render full PRESENT pages merely to create thumbnails.
7. Selected page is visually obvious.
8. Page operations apply to the selected authored page.
9. Drag-and-drop reordering is deferred.
10. Only one authored page's Markdown is visible/editable at a time.
11. No separate image library/gallery is included in MVP.
12. Image upload is initiated from the editor and inserts the resulting Markdown image reference at the current cursor position.
13. Autosave status is quiet and placed near `View Presentation`.
14. No routine manual Save button is required.

---

## 5.2 Metadata / Generated Title Page

```text
MEMORY DETAILS

Title       [ Taiwan 2026                                      ]
Start       [ 2026-02-03 ]       End [ 2026-02-17 ]
Subtitle    [ February 3–17, 2026                              ]
Key photo   [ thumbnail ] [ Change ]
```

Selecting the `Title` thumbnail in the page strip should focus/identify the metadata/title-page section rather than expose generated page-boundary Markdown.

Metadata remains independent from authored page Markdown.

---

## 5.3 Page Strip

```text
PAGES

[ Title ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] [ 6 ] [ 7 ]  → horizontal scroll →  [ + ]
                    └ selected
```

Thumbnail content may schematically indicate image/text presence:

```text
┌──────┐
│ ▣▣   │
│ ───  │
│ ──   │
└──────┘
```

Do not require screenshot-quality thumbnails.

---

## 5.4 Page Reordering / Deletion

```text
Page 4                         [ Move Earlier ] [ Move Later ] [ Delete Page ]
```

- Controls are associated with the selected page, not repeated on every thumbnail.
- Delete should require an appropriate lightweight confirmation because it destroys authored page content.
- Reordering updates the application-managed Markdown page order.

---

## 5.5 Markdown Editor and H2 Boundary Warning

The page editor represents exactly one Memory Page.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ ![photo](...)                                                              │
│                                                                            │
│ - Dinner with family                                                       │
│ - We weren't originally planning to...                                     │
│                                                                            │
│ ## This is not allowed here                                                │
└────────────────────────────────────────────────────────────────────────────┘

⚠ Level-2 headings define Memory Pages and are not allowed inside a page.
  This heading will be removed or converted when saved.
```

### Rules

- Application owns H2 (`##`) boundaries.
- Typing H2 inside the selected page must not silently create a new page.
- Warning should be inline/non-blocking rather than a modal alert when practical.
- Exact sanitization/conversion behavior belongs in Feature Specification.

---

## 5.6 Image Upload / Insert at Cursor

MVP deliberately avoids an image-management sidebar or gallery.

```text
Markdown editor
┌────────────────────────────────────────────────────────────────────────────┐
│ - We went to the zoo.                                                      │
│                                                                            │
│ [cursor]                                                                   │
└────────────────────────────────────────────────────────────────────────────┘

[ Add Picture at Editor Cursor ]
```

Interaction intent:

1. User places cursor.
2. User selects `Add Picture at Editor Cursor`.
3. User selects a JPG/JPEG from the local computer.
4. Upload is persisted with its original filename preserved according to Architecture rules.
5. Presentation derivative is generated after upload/commit processing.
6. Markdown image reference is inserted at the cursor.

MVP does not provide a visual library of previously uploaded/unused images.
MVP does not provide per-image deletion.
Unused assets may accumulate and are handled by a future maintenance feature.

---

## 5.7 Autosave

Normal state:

```text
Saved 8:42 PM                              [ View Presentation ]
```

During persistence:

```text
Saving…                                    [ View Presentation ]
```

### Rules

- Autosave occurs in the background no less frequently than once per minute when changes exist.
- Changing selected Memory Page persists pending changes.
- `View Presentation` persists pending changes before navigation if necessary.
- Do not display repetitive toast notifications for successful autosaves.
- Autosave never automatically advances to PRESENT.

---

# 6. Theme

## 6.1 Dark Default

All wireframes should be interpreted as dark-first even though ASCII cannot represent color.

- Dark is the initial default.
- Light may be selected at Timeline bottom.
- Preference persists in browser storage.
- EDIT must have a complete dark appearance.
- PRESENT surroundings are dark by default.

---

# 7. Image Rendering / Thumbnail UX Constraints

This section describes UX intent, not the final image-processing architecture.

### PRESENT derivative

- Do not perform expensive real-time image downsampling during PRESENT.
- PRESENT should use a pre-generated reduced image derivative.
- Current product direction calls this an `original_300ppi` derivative, while the exact pixel/PPI interpretation must be resolved in Architecture because web rendering is fundamentally pixel-dimension based.

### Timeline thumbnail

Timeline key photos should use a substantially smaller pre-generated or efficiently derived thumbnail than the PRESENT image.

The thumbnail is only approximately 2–3 lines of text tall and should not require transferring a presentation-sized asset merely to display it.

Architecture should determine an appropriate pixel-dimension/quality target. A conceptual “~100 PPI” is not itself sufficient because rendered pixel dimensions and device density determine bandwidth.

### Image invariants

- Never alter the source image aspect ratio.
- Avoid unnecessary runtime server processing during normal presentation.
- Prefer preprocessing when assets are uploaded/committed.

---

# 8. Motion and Interaction Feedback

MVP uses minimal motion.

- No decorative Timeline animation.
- No page-flip animation.
- No animated cards.
- No required crossfade between Memory Pages.
- Swipe may provide only minimal direct manipulation/transition feedback if naturally supplied by implementation.
- Respect browser reduced-motion preferences.
- Interaction state changes should be immediate and predictable.

---

# 9. Deferred Wireframes

Do not design these as active MVP surfaces yet:

- SHARE page with unguessable URL and QR code;
- used/unused asset maintenance page;
- bulk `Delete unused pictures` workflow;
- server-folder image browser;
- full image library in EDIT;
- drag-and-drop page ordering;
- exact live PRESENT thumbnails inside EDIT;
- user-selectable scrapbook templates;
- sophisticated Timeline collision resolution;
- maps, locations, comments, search, social features, video.

The underlying architecture should avoid making future SHARE and asset-maintenance surfaces unnecessarily difficult.

---

# 10. Implementation Priority for First UI Pass

When translating these wireframes into the first functional UI, prioritize in this order:

1. Correct Timeline proportional geometry and navigation.
2. Correct landscape PRESENT behavior and image aspect preservation.
3. Reliable Previous/Next/swipe/keyboard navigation.
4. Functional EDIT metadata + one-page-at-a-time Markdown editing.
5. Page strip and add/delete/reorder operations.
6. Image upload and insertion at cursor.
7. Autosave feedback and behavior.
8. Timeline thumbnails and compact label tuning.
9. Responsive portrait Timeline.
10. Visual polish and spacing adjustments using real Memories on target devices.

Do not sacrifice correct data/date behavior or reliable authoring in order to prematurely polish visual styling.
