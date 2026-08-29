# Memory Markdown v1

Durable file contract for one Memory's `memory.md`.

See also:

- `docs/architecture.md` §§5, 8, 11
- `docs/feature_specifications.md` F3, F4
- `docs/decisions/002-memory-directory-names.md`

This document is the parser/serializer contract. Tests should round-trip:

``` text
parse -> representation -> serialize -> parse
```

The final semantic Memory must be equivalent to the initial one even if
formatting is normalized.

## File

Each Memory directory contains exactly one authoritative Markdown file
named `memory.md`.

One Memory is one file. Do not create one Markdown file per page.

## Front matter

The file begins with YAML front matter delimited by `---` lines.

`id` is required and is the stable integer Memory identity. It is not
zero-padded in YAML (`42`, not `042`).

Portable fields:

``` yaml
id: 42
title: Taiwan 2026
start_date: 2026-02-03
end_date: 2026-02-17
key_photo: IMG_1234.jpg
subtitle: Taiwan and Hong Kong
```

Optionality:

- `id` is always present.
- `title`, `start_date`, `end_date`, `key_photo`, and `subtitle` are
  omitted when unset. Do not serialize empty strings for these fields.
- `end_date` is optional even on a complete Memory (a single-day Memory
  may omit it).
- Dates use ISO `YYYY-MM-DD`.

Incomplete drafts are valid files. A new draft may contain only:

``` markdown
---
id: 1
---
```

Unknown front-matter keys are ignored on parse and are not rewritten on
serialize.

## Title-level body (H1)

`#` is Memory/title-level content. The application generates it from
structured metadata:

- When `title` is present, serialize `#` followed by the title.
- When `subtitle` is also present, serialize it as a paragraph after H1.
- Incomplete drafts with no title omit H1.

The title-page body is not independently authored. On parse, metadata
comes from YAML, not from H1 text. Extra H1-body text that is not the
subtitle is dropped on the next serialize.

## Authored pages (H2)

A line that matches `##` followed by a space or end-of-line, and that is
not `###` or deeper, starts an authored Memory Page.

The remainder of that line is the page heading. A blank heading is
allowed (`##` with nothing after the marker).

The page body is the text after the heading line until the next H2
boundary. The application owns H2 boundaries.

### H2 inside a page body (EDIT sanitization)

EDIT presents one page at a time. The H2 heading is an
application-owned field, not typed as `##` in the page body.

If the selected-page **body** contains a line that matches an H2
boundary (`##` followed by a space or end-of-line, not `###` or
deeper):

- do not create another Memory Page;
- strip the `##` marker (and the following space, if any) so the line
  becomes an ordinary paragraph;
- keep the rest of that page's body in the same page.

`###` and deeper headings in a page body are left unchanged.

A blank page heading is allowed and serializes as `##` with nothing
after the marker.

The user must use Add Page to create a new page.

Image references are ordinary Markdown images whose paths are filenames
inside the same Memory directory:

``` markdown
![Taipei](IMG_1234.jpg)
```

## Serialization order

Serialize front-matter keys in this order when present:

1. `id`
2. `title`
3. `start_date`
4. `end_date`
5. `key_photo`
6. `subtitle`

Then H1/subtitle when a title exists, then H2 pages in order.

A formatting-normalized round trip may differ textually (spacing,
omitted empty keys) while preserving semantic content: identity,
metadata, page headings, and page bodies.

## Parsing failures

Missing `id`, missing front-matter delimiters, or YAML that is not a
mapping are parse errors.

A parse error isolates that Memory. It must not take down unrelated
Memories.
