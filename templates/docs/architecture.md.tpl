# Architecture

How {{PROJECT_NAME}} works *today*. This is a **living document** — update it as the system evolves, not as a historical log (for history, use `git log`<!-- FULL-ONLY --> or `docs/adr/`<!-- /FULL-ONLY -->).

> Keep this document about *what exists*, not *why it was chosen that way*. For the "why", link to<!-- FULL-ONLY --> the relevant ADR in `docs/adr/` or<!-- /FULL-ONLY --> a dated entry in `docs/lessons-*.md`.

## Overview

<!-- One paragraph: what does this system do, who uses it, what are the main moving parts. -->

## Major components

<!-- One subsection per major module/service/layer. Keep each tight — link to code rather than duplicating it. -->

### Component A

### Component B

## Data model

<!-- Core entities and their relationships, if relevant. A diagram (even ASCII) beats a wall of text. -->

## Key flows

<!-- The 2-4 flows that matter most to understand the system (e.g. request lifecycle, main background job, auth flow). -->

## Cross-cutting concerns

<!-- Auth, permissions, logging/observability, error handling conventions — whatever spans multiple components. -->
