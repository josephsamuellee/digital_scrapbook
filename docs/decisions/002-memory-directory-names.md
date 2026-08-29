# ADR-002: Memory directory names use a random suffix

Status: Accepted
Date: 2026-08-28

## Context

Architecture examples originally showed a title-derived slug
(`042-taiwan-2026`). A draft can be allocated before a title exists, and
directories must not be renamed when the title later changes.

## Decision

Memory directories use the stable numeric ID, zero-padded to three
digits, plus a random 10-digit suffix:

``` text
042-5831047291/
```

The prefix is identity. The suffix is only for unique allocation. Do not
derive the directory name from the title, and do not rename the
directory after creation.

## Reasons

A random suffix can be chosen before metadata exists. Title slugs would
either delay directory creation or require a later rename, which the
architecture forbids.

## Consequences

Directory names are not human-readable labels. Identity remains the
stable integer ID in YAML, SQLite, and routes. Architecture examples
must match this convention.
