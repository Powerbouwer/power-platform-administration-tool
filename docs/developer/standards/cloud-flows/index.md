---
title: Cloud flow standards
---

# Cloud flows

See the [shared standards and continuous integration policy](../). Use solution-aware flows and choose an appropriate subject. A generic inventory search doesn't need an artificial table-specific name.

## Naming rules

<a id="cfl-001"></a>

### Cloud flow display-name validation

**Automated check:** `Workflow.@Name` must contain a non-whitespace display name. Good: `Inventory Search`. Bad: a blank or nil name. The rule checks display-name metadata. It ignores JSON file names and action keys.

<a id="ppat-002"></a>

### Cloud flow naming convention

**Automated check, team convention:** Use **PPAT Module - Subject - Purpose**. The readable `PPAT` label isn't derived from the technical publisher prefix.

- Good: `PPAT Core - Inventory - Search Resources`.
- Child flow example: `PPAT Core - Child Flow Inventory - Validate Request`.
- Bad: `Flow 1` or `Inventory Update`.

Use readable English words and ASCII `-` separators. The module and subject can contain multiple words. The current pattern doesn't verify module ownership, grammar, or the business meaning of the purpose. Rename the flow in its details or designer, then sync its metadata.

**Coverage:** These rules inspect the `@Name` display-name field in native `modernflows/<id>/workflow.yml` metadata with `Category: 5` (cloud flow). They don't check definition-only JSON, action names, or trigger labels.

## Naming guidance (manual review required)

- Triggers: describe the trigger, subject and relevant change type, for example `When an Environment Is Modified`.
- Recurrence: `Recurrence | Every 10 Minutes`, matching the actual schedule.
- Actions: keep recognizable operation wording and add context, for example, `List Rows | Active Environments`. Don't depend on exact localized connector labels.
- Variables: use `var` for scalar state, `arr` for arrays, and `obj` for objects, followed by a descriptive purpose. Dates aren't a separate Initialize Variable type.
- Connection references and environment variables: include solution/module context and a meaningful purpose, not an unexplained generated suffix.

## Design review (manual review required)

- Use outputs or Compose for derived values. Use variables only for mutable state, and initialize them in supported locations.
- Filter and project at the source when useful. Reuse existing outputs before adding more API calls.
- Group complex work with scopes. Provide observable failure handling with appropriate run-after paths. Three Try/Catch/Finally scopes are one pattern, not a required template.
- Configure concurrency only after checking shared state, order, idempotency, and connector throttling. Keep default retries when they're sufficient. Use care with retries on writes.
- Define child-flow inputs/outputs and validate them. Prefer creating parent and child in the same solution. Don't require a separate utility solution for every child flow.
- Use connection references and environment-specific configuration. Choose manageable identities supported by the connector, not a blanket service-account requirement.
- A signed HTTP-trigger address may contain credentials. Don't treat a text environment variable as secure secret storage.
- Provide a flow description and notes for non-obvious decisions. Return useful errors without exposing credentials or sensitive trigger data.

These points are review guidance, not additional build blockers. This naming check can't verify licensing, connection ownership, production state, or runtime performance.
