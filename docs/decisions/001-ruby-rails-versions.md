# ADR-001: Ruby 4.0.5 and Rails 7.2.3

Status: Accepted
Date: 2026-08-28

## Context

The production Raspberry Pi already runs Ruby 4.0.5 and Rails 7.2.3.
The application should stay on those versions rather than adopting a
newer Rails major that the server does not yet provide.

## Decision

Pin the application to Ruby 4.0.5 and Rails 7.2.3.

## Reasons

Matching the installed production runtime avoids a parallel upgrade of
the Pi just to start the MVP. Rails 7.2.3 is sufficient for
server-rendered HTML, SQLite, import maps, and Stimulus. Extra gems and
Rails 8 defaults (Solid Queue, Kamal, etc.) are not required.

## Consequences

Development must use Ruby 4.0.5. Do not move to Rails 8 without an
explicit decision and a matching production runtime. Prefer stdlib,
Rails, and existing Pi tools (`magick`, `heif-convert`) before adding
gems.
