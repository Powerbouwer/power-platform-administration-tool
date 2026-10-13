---
title: "🧭 Use a generic cloud flow for inventory searches"
issue: 20
issueUrl: https://github.com/Powerbouwer/power-platform-administration-tool/issues/20
scope: "Core"
decisionDate: 2026-10-13
---

# 🧭 Use a generic cloud flow for inventory searches

Source: [Issue #20](https://github.com/Powerbouwer/power-platform-administration-tool/issues/20)

### Scope

Core

### Context and problem statement

PPAT needs to search Power Platform inventory from the app. Inventory can be queried through Azure Resource Graph, PowerShell, or the Power Platform API, including the Power Platform for Admins V2 connector.

Calling the admin connector directly from a canvas app or custom page requires the querying account to have the Power Platform Administrator role. Requiring that role for every app user is not the intended model. The connector appears usable directly from the app now, but that does not remove the permission requirement.

We need a way to run inventory queries with an appropriately privileged connection while controlling which users can search through PPAT.

### Decision drivers

- Avoid requiring every app user to have the Power Platform Administrator role.
- Control which users can search through PPAT’s security rules.
- Keep inventory querying consistent across resource types.
- Minimize the number of flows and the maintenance burden.

### Considered options

- Call the Power Platform for Admins V2 connector directly from the app: avoids an intermediary flow, but the querying identity still needs the Power Platform Administrator role.
- Query through Azure Resource Graph: an alternative inventory query path, but not the selected app-facing approach.
- Query through PowerShell: another alternative, but not the selected app-facing approach.
- Create a separate cloud flow per resource type or query: permits specialized flow logic, but increases the number of flows and their maintenance burden.
- Use one generic cloud flow as a middle layer: centralizes the privileged connector call and provides a consistent query path, while leaving resource-specific handling in the app.

### Decision outcome

We will use one generic cloud flow as the middle layer for inventory searches. The flow will use a connection reference for the Power Platform for Admins V2 connector, bound to an account with active Power Platform Administrator rights.

The flow will accept the query clauses as text, parse and pass them to the inventory connector, and return the results to the app. The app will handle resource-specific parsing and presentation in its custom pages. PPAT security rules will determine which users are permitted to search.

This approach centralizes the privileged connection and avoids maintaining separate flows for each resource type or query.

### Consequences

Positive:
- App users do not each need the administrator role for the connector call.
- The privileged connection and inventory query path are centralized.
- A single flow-level change can apply consistently across resource types.
- Resource-specific parsing and presentation can remain in the relevant custom pages.

Negative or trade-offs:
- The flow adds an intermediary hop and may not be optimal for performance.
- The shared flow must remain generic as inventory needs evolve.
- The connection reference must remain bound to an account with active Power Platform Administrator rights.
- Access control must be maintained so only permitted users can initiate searches.

Follow-up:
- Revisit this decision if performance, resource-specific behavior, or security requirements change. Consider specific flows if the generic flow no longer meets those needs.

### Participants

@miguelverweij 
@arijsdijk 

### Links

_No response_
