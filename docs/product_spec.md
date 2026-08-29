# Product Specification — Digital Scrapbook MVP

**Status:** MVP product definition  
**Document role:** Product requirements and product-level behavioral contract  
**Audience:** Human maintainers and AI coding agents  

## 1. Product Summary

Digital Scrapbook is a private, lightweight, browser-based application for authoring, retrieving, and presenting short visual memories over time.

The fundamental object is a **Memory**. A trip is a common type of Memory, but the product must not assume that every Memory represents travel.

The application replaces a collection of PowerPoint-style presentations with an open, browser-native system. Memories are authored ahead of time and are normally presented by the owner while clicking or swiping through them for another person.

The primary navigation mechanism is a chronological **Timeline**, not a file directory, album grid, map, or photo gallery.

## 2. Product Problem

The existing PowerPoint-based workflow has several problems:

- Access may depend on proprietary software, licensing, or account controls.
- Presentations exist in a flattened directory organized primarily by filename.
- Identifying an old presentation often requires downloading and opening files individually.
- Key photographs are not visible while browsing the collection.
- PowerPoint is heavier than necessary for presentation from a phone.
- The presentation format is proprietary and undesirable as the long-term canonical representation of personal memories.

The application should provide one lightweight website where Memories can be visually browsed by date, opened quickly, and presented directly in a browser.

## 3. Product Goals

The MVP shall:

1. Allow the owner to create and edit Memories through a browser.
2. Store Memory content in human-readable Markdown.
3. Store photographs as ordinary image files alongside the Memory content.
4. Preserve uploaded originals while creating presentation-optimized image derivatives at edit/save time.
5. Provide a reverse-chronological, proportional Timeline as the homepage.
6. Make Memories identifiable from their date, title, and key photo without opening every Memory.
7. Present each Memory as a sequence of landscape-oriented Memory Pages.
8. Work well from a mobile browser without requiring a standalone application.
9. Remain lightweight enough to run on a Raspberry Pi 4 shared with other services.
10. Preserve portability so that the application is not the only usable representation of the archive.

## 4. Non-Goals

The MVP is explicitly **not**:

- a photo gallery;
- a photo backup service;
- a Google Photos replacement;
- a travel planning or booking application;
- a map or location-history application;
- a social network;
- a commenting or feedback system;
- a voting or reaction system;
- a collaborative editing platform;
- an RSS publishing system;
- a video hosting system;
- a native iOS or Android application;
- an animation-heavy presentation application;
- a PowerPoint-compatible editor.

There is no requirement for application-level user accounts, roles, or permissions in the MVP.

## 5. Target User and Usage Model

The MVP has a single conceptual owner/author.

The owner authors Memories in advance using the browser-based EDIT interface. Editing is expected primarily from a regular desktop browser rather than from a phone.

Presentation is expected to happen frequently from a mobile browser. The owner typically controls the presentation while showing it to another person.

External infrastructure may restrict access to the application. The MVP must not implement its own authentication system.

Future versions may support unguessable shareable URLs for individual Memories, but public sharing behavior is outside MVP scope.

## 6. Core Domain Model

### 6.1 Memory

A **Memory** is the fundamental persistent content object.

Examples include:

- Taiwan 2026
- Christmas 2025
- Our Wedding
- Grand Canyon
- First Week in California

A Memory is defined once an entry has:

- a title;
- a start date;
- an optional end date; and
- at least one image.

The explicitly entered dates are authoritative. GPS metadata, EXIF dates, inferred locations, filenames, or other image metadata must not override the Memory dates.

A Memory may represent a single day or a date range.

### 6.2 Memory Page

A Memory contains an ordered collection of **Memory Pages**.

A Memory Page is one presentation viewport, analogous to a scrapbook page rather than a scrolling section of a website.

Each content Memory Page supports at most:

- 3 images; and
- 3 text blocks.

Typical Memories are expected to contain approximately one page per trip day and normally no more than roughly 20 pages. This is an expected usage pattern, not necessarily a hard storage limit unless later Feature Specifications define one.

Text is normally concise and bullet-oriented, but several paragraphs must remain possible when necessary to preserve a memory.

### 6.3 Title Page

Every Memory has a first/title page.

The initial title page is automatically generated from Memory metadata and includes at minimum:

- the Memory title as the primary centered heading; and
- a secondary centered line derived from metadata, such as the date/date range.

The generated title-page content must be editable through EDIT mode.

## 7. Canonical Content and Portability

Long-term portability is a product requirement.

The application must not become the only usable representation of the archive.

Canonical long-form Memory content shall be stored as Markdown. Images shall remain ordinary image files. The storage design should make it practical to inspect, copy, back up, or migrate a Memory without requiring the application to render it first.

A Memory's Markdown and associated images should belong together in the filesystem.

Conceptually:

```text
memories/
  taiwan-2026/
    memory.md
    taipei.jpg
    taipei_300ppi.jpg
    zoo.jpg
    zoo_300ppi.jpg
```

The exact directory naming and metadata representation are architecture decisions, not requirements of this Product Specification.

## 8. Image Handling

### 8.1 Upload

MVP EDIT mode shall allow the author to upload JPG/JPEG images.

The editor shall provide a convenient control for inserting an uploaded image into the Markdown content rather than requiring the author to manually construct image paths.

Browsing arbitrary existing server directories is deferred beyond MVP.

### 8.2 Original and Presentation Derivative

The application shall preserve the uploaded original image.

After upload/commit, the application shall generate a presentation-oriented derivative rather than resampling images dynamically during presentation requests.

The intended naming convention is:

```text
original-name.jpg
original-name_300ppi.jpg
```

The original upload filename should be preserved where safely possible. Filename conflict and sanitization behavior shall be defined in Architecture or Feature Specifications.

The presentation derivative is intended to reduce network bandwidth and runtime processing during PRESENT mode.

The current product target is described as a **300 ppi presentation derivative**. The precise resampling algorithm, pixel dimensions, EXIF behavior, quality settings, and interpretation of ppi shall be defined technically during Architecture/Feature Specification work rather than inferred by an implementation agent.

## 9. Markdown Content Convention

Markdown is the authoring representation for Memory content.

MVP uses a deliberately small convention:

- `#` represents the Memory/title-level content.
- Each `##` begins a new content Memory Page.
- The first three images occurring within a page section may be rendered on that page.
- Text within the section supplies the page's text content.
- Markdown bullet lists are supported and are the default expected writing style.

Example:

```markdown
# Taiwan 2026

February 3–17, 2026

## February 4

![Taipei](taipei_300ppi.jpg)

- Arrived in Taipei
- Dinner with family

## February 5

![Zoo](zoo_300ppi.jpg)

- Taipei Zoo
- Surprisingly empty that morning
```

The exact parser grammar, invalid-content behavior, image association rules, and handling of more than three images/text blocks belong in the relevant Feature Specification.

The Markdown format should remain understandable to a human without the application.

## 10. Key Photo

Every Memory requires a **key photo** used for identification on the Timeline.

On initial creation, the application shall default the key photo to the first uploaded/used image.

EDIT mode shall allow the author to explicitly change the key photo.

The key-photo designation should be represented efficiently and portably. It may use Markdown metadata/front matter, a documented tag, or another simple representation. The exact syntax is an Architecture/Feature Specification decision and must not be independently invented by an implementation agent before that decision is documented.

## 11. Primary Application Views

The MVP contains three primary product concepts:

1. **TIMELINE** — homepage and archive navigation.
2. **PRESENT** — page-by-page Memory presentation.
3. **EDIT** — creation and authoring interface.

Detailed information architecture and screen composition belong in the UX/Information Architecture specification.

## 12. TIMELINE Requirements

### 12.1 Purpose

TIMELINE is the homepage and primary archive navigation mechanism.

Its purpose is to let the owner quickly understand and retrieve Memories based on when they happened, their titles, and their key photographs.

TIMELINE must not become a conventional album/photo grid.

### 12.2 Ordering

Years are displayed in reverse chronological order, with the most recent represented year first.

Only years containing at least one Memory shall be rendered.

For example, if Memories exist only in 2026 and 2024, the application shall not generate an empty 2025 timeline solely because that calendar year exists.

### 12.3 Year Scale

Each year is represented by one horizontal Jan 1 → Dec 31 timeline.

The complete year must fit horizontally within the available viewport. The user must not need horizontal scrolling to inspect one year.

Memory positions and duration segments shall be proportional to their actual dates within the calendar year.

Conceptually:

```text
x = (day_of_year - 1) / (days_in_year - 1)
```

Implementations must account correctly for leap years.

Quarter markers are sufficient. Month markers are not required for MVP.

The available timeline width should adapt to the display/viewport rather than assuming a fixed desktop width.

### 12.4 Memory Duration

A multi-day Memory is represented by a horizontal segment from its start date through its end date.

A single-day Memory may be represented as a point or zero/near-zero duration marker according to the later visual specification.

All Memory duration segments should preferably share the same primary horizontal timeline rather than being assigned separate timeline lanes merely because Memories overlap.

Labels/key-photo callouts may be staggered vertically beneath the timeline to preserve readability.

Sophisticated collision detection is desirable but is not required for MVP unless later UX specifications make it necessary for basic usability.

### 12.5 Cross-Year Memories

A Memory may span December → January and remains one Memory.

For a cross-year Memory:

- the relevant duration portion must be represented in each affected year;
- both representations navigate to the same Memory;
- the primary key-photo/title callout should appear in the year containing the larger portion of the Memory;
- if duration is equal, the more recent year should be preferred unless later UX specifications define another deterministic rule.

Example:

`Dec 28, 2026 – Jan 4, 2027` appears on both year timelines, while its primary callout belongs to the year containing the greater duration according to the defined date-counting convention.

### 12.6 Timeline Density

Expected content density is low: normally no more than approximately one Memory per month.

The layout should be vertically compact enough that, on an appropriate landscape viewport, the user can generally see at least two complete year timelines while vertically scrolling through the archive.

This is a design target rather than a guarantee across every screen dimension.

### 12.7 Timeline Memory Identification

A Memory should be identifiable from:

- its proportional date/duration position;
- title;
- key photo; and
- date/date range where appropriate.

Selecting the Memory navigates to its PRESENT mode.

## 13. PRESENT Requirements

### 13.1 Presentation Model

PRESENT displays exactly one Memory Page at a time.

It behaves more like a lightweight presentation/scrapbook than a vertically scrolling article.

On mobile, PRESENT is designed primarily for landscape orientation.

Normal vertical page scrolling between Memory Pages shall not be required on mobile.

### 13.2 Navigation

MVP PRESENT navigation shall support:

- visible previous/next controls;
- mobile horizontal swipe gestures;
- keyboard Left Arrow / Right Arrow; and
- keyboard `h` / `l` navigation for Vim-style operation.

Navigation moves exactly one Memory Page backward or forward.

### 13.3 Default Content Page Layout

MVP requires only one default content-page presentation template.

For a typical landscape viewport:

- one image is the dominant visual element;
- approximately 70–80% of available page width may be devoted to the image;
- the remaining region contains Markdown-rendered text, normally bullets;
- a typical 3:2 landscape photograph should scale down to fit rather than requiring expensive runtime transformation.

Exact dimensions and responsive rules belong in annotated wireframes and Feature Specifications.

Although the data convention permits up to three images and three text blocks per page, sophisticated templates for different image counts/aspect ratios are deferred. MVP behavior for 2–3 images must be deterministic and documented before implementation.

Future template support should be possible for:

- portrait photographs;
- landscape photographs;
- 4:3 images;
- 3:2 images; and
- different combinations of images and text.

### 13.4 End of Memory

After the final content page, PRESENT shall provide an end state containing at minimum:

- **Back to Timeline**; and
- **Edit Memory**.

This makes EDIT intentionally discoverable at the end of a presentation without placing prominent editing controls throughout PRESENT mode.

## 14. EDIT Requirements

MVP EDIT must be sufficient for the owner to begin populating the archive.

At minimum, the author can:

- create a Memory;
- set/edit title;
- set/edit start date;
- set/edit optional end date;
- upload JPG/JPEG images;
- insert uploaded-image references into Markdown through an editor control;
- edit Memory Markdown;
- select/change the key photo; and
- save/commit the Memory.

Saving/committing must perform any required image preprocessing outside the presentation request path.

A live visual presentation preview is explicitly **not required for MVP**.

A future EDIT experience may add:

- live preview;
- presentation templates;
- visual page-layout selection;
- server-side existing-image browsing; and
- richer assistance for composing Markdown.

## 15. Theme and Visual Direction

The application shall default to **dark mode**.

A user-accessible toggle shall allow switching to a light theme.

The visual design should remain simple and presentation-focused. Fancy transitions, decorative animations, and heavy UI frameworks are not product goals.

## 16. Performance and Resource Principles

The application is intended to run on a Raspberry Pi 4 alongside other services.

Future development must preserve the following principles:

- Keep server-side work modest.
- Prefer static/preprocessed presentation assets over repeated runtime image processing.
- Presentation requests should primarily involve network transfer of already-prepared assets plus lightweight rendering.
- Avoid unnecessary compilation/build complexity.
- Keep client and server dependencies proportionate to the small scope of the application.
- Optimize PRESENT for responsive use on a phone/browser.
- Perform expensive image resampling when content is committed rather than while it is being presented.

Exact performance budgets belong in Architecture/Feature Specifications if required.

## 17. Maintainability Principles

The project should remain open, understandable, and maintainable over many years.

Future changes should preserve:

- conventional/open file formats;
- Markdown portability;
- ordinary image files;
- clear separation between canonical content and generated presentation assets;
- simple architecture appropriate for a personal application;
- documentation sufficient for a new human engineer or AI coding agent to identify architectural boundaries before changing code;
- minimal hidden conventions;
- explicit feature contracts rather than behavior inferred only from implementation.

The application should favor boring, well-documented solutions over unnecessary abstraction.

## 18. Authentication and Sharing

MVP implements no application-level authentication, user accounts, roles, or per-Memory access controls.

Access is assumed to be protected by infrastructure outside the application.

Future versions may provide individual Memories with unguessable shareable URLs. The MVP architecture should avoid unnecessarily preventing this capability, but no sharing workflow needs to be implemented now.

## 19. MVP Success Criteria

The MVP is successful when the following end-to-end scenario works:

> Starting with an empty application, the owner can create a Memory, provide its title and dates, upload JPG images, author its pages using the documented Markdown convention, save it, find it at the correct proportional position on the reverse-chronological Timeline, open it, and present the complete Memory in landscape orientation using page-by-page navigation on a phone or desktop browser.

Additionally:

> After multiple Memories across multiple years have been entered, the owner can visually browse their history without opening individual files and identify Memories from their dates, titles, and key photos.

## 20. MVP Scope Summary

### Required

- Memory as fundamental object
- Browser-based application
- TIMELINE homepage
- Reverse-chronological year ordering
- Only years containing Memories
- Full-year proportional horizontal timeline
- Quarter reference markers
- Date-range/duration visualization
- Cross-year Memory representation
- Key photo + title identification
- PRESENT mode
- Landscape-first mobile presentation
- One Memory Page per viewport
- Previous/next controls
- Mobile swipe navigation
- Arrow-key navigation
- `h` / `l` keyboard navigation
- Automatic editable title page
- Markdown-backed content
- `##` page boundaries
- Up to 3 images / 3 text blocks per content page
- Browser EDIT mode
- JPG/JPEG upload
- Editor-assisted image insertion
- Required key photo
- Preserve original image
- Generate presentation derivative on commit
- Dark mode default
- Light-mode toggle
- End-of-Memory navigation to Timeline or EDIT
- No application-level authentication

### Deferred

- Live EDIT preview
- Advanced page templates
- Visual/WYSIWYG editing
- Sophisticated timeline collision detection
- Arbitrary server-folder image browser
- Location/map functionality
- EXIF/GPS-based organization
- Search
- Places/people indexes
- Statistics/retrospectives
- PowerPoint import
- AI functionality
- Multi-year comparison-specific view beyond normal stacked yearly timelines
- Public sharing workflow
- Unguessable Memory sharing URLs
- Collaboration
- Video
- Native mobile applications

## 21. Requirements Precedence

This document defines **product intent and MVP scope**, not implementation details.

When later documents exist, use the following responsibility boundaries:

1. **Product Specification** — why the product exists, scope, domain concepts, and product-level behavior.
2. **UX / Information Architecture** — screens, navigation, information hierarchy, interaction model, and responsive UX.
3. **Architecture Specification** — storage, runtime components, deployment, data structures, processing boundaries, and technical constraints.
4. **Annotated Wireframes** — precise visual layout and interaction placement.
5. **Feature Specifications** — detailed behavior, edge cases, parsing rules, state transitions, and error handling.
6. **Acceptance Criteria** — objectively testable completion requirements.

An implementation agent must not silently invent unspecified behavior when a requirement materially affects persistent data, portability, navigation, or user-visible behavior. Such ambiguity should be resolved in the appropriate specification first.
