---
title: "🧭 Use a generic cloud flow for inventory searches"
issue: 20
issueUrl: https://github.com/Powerbouwer/power-platform-administration-tool/issues/20
scope: "Core"
decisionDate: 2026-10-13
---

# 🧭 Use a generic cloud flow for inventory searches

Source: [Issue #20](https://github.com/Powerbouwer/power-platform-administration-tool/issues/20)

## Scope

Core

## Context and problem statement

The app needs to search Power Platform inventory. It can query inventory through Azure Resource Graph, PowerShell, or the Power Platform API, including the Power Platform for Admins V2 connector.

The account that calls the admin connector directly from a canvas app or custom page must have the Power Platform Administrator role. Requiring every app user to hold that role isn't the intended model. The connector now appears usable directly from the app, but users still need the required permission.

The app needs an appropriately privileged connection for inventory queries and a way to control who can search.

## Decision drivers

- Avoid requiring every app user to have the Power Platform Administrator role.
- Apply PPAT security rules to limit who can search.
- Keep inventory querying consistent across resource types.
- Minimize the number of flows and the maintenance burden.

## Considered options

- Call the Power Platform for Admins V2 connector directly from the app: avoids an intermediary flow, but the querying identity still needs the Power Platform Administrator role.
- Query through Azure Resource Graph: an alternative inventory query path, but not the selected app-facing approach.
- Query through PowerShell: another alternative, but not the selected app-facing approach.
- Create a separate cloud flow per resource type or query: permits specialized flow logic, but increases the number of flows and their maintenance burden.
- Use one generic cloud flow as a middle layer: centralizes the privileged connector call and provides a consistent query path, while leaving resource-specific handling in the app.

## Decision outcome

The app will use one generic cloud flow as the middle layer for inventory searches. The flow will use a connection reference for the Power Platform for Admins V2 connector and an account with active Power Platform Administrator rights.

The flow will accept query clauses as text, parse them, pass them to the inventory connector, and return the results to the app. Custom pages will handle resource-specific parsing and presentation. PPAT security rules will determine which users may search.

This approach centralizes the privileged connection and avoids maintaining separate flows for each resource type or query.

## Consequences

Positive:

- App users don't each need the administrator role for the connector call.
- One flow centralizes the privileged connection and inventory query path.
- A single flow-level change can apply consistently across resource types.
- Resource-specific parsing and presentation can remain in the relevant custom pages.

Negative or trade-offs:

- The flow adds an intermediary hop and may not be optimal for performance.
- The shared flow must remain generic as inventory needs evolve.
- The connection reference must remain bound to an account with active Power Platform Administrator rights.
- Maintain access controls so only permitted users can initiate searches.

Follow-up:

- Revisit this decision if performance, resource-specific behavior, or security requirements change. Consider specific flows if the generic flow no longer meets those needs.

## Participants

@miguelverweij
@arijsdijk

## Links

No response
