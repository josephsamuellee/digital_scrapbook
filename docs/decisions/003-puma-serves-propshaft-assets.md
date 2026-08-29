# ADR-003: Puma serves Propshaft assets in production

Status: Accepted
Date: 2026-08-29

## Context

Production is `bin/rails server -e production -p 8086` with no nginx
or other static file server. Propshaft fingerprints `/assets/...` URLs
in HTML in every environment, but `config.assets.server` is
development/test-only by default. `ActionDispatch::Static` only serves
files that already exist under `public/`. Deploy does not run
`rails assets:precompile`, so `public/assets` is empty.

The result is `ActionController::RoutingError` for every JS/CSS
request. Stimulus never loads, so EDIT image upload cannot insert a
Markdown reference after the author selects a file.

## Decision

Enable `config.assets.server = true` and
`config.public_file_server.enabled = true` in production so Puma serves
Propshaft JS/CSS from the application load path.

## Reasons

Direct LAN and cloudflared both terminate on Puma. Serving assets from
Rails is the smallest change that matches that topology and the current
start command, which does not precompile assets.

## Consequences

Production does not require an `assets:precompile` step. A later
reverse proxy may serve precompiled files instead; this setting can then
be turned off. Application JS/CSS remain available without Cloudflare-
specific headers.

## Supersedes / Superseded by

None.
