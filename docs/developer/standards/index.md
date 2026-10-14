# Power Platform standards

These are PPAT team standards for **cloud flows, Canvas apps, model-driven apps and Dataverse**. They apply to all resources of these types in the solution being changed, not just to the edited files. Solution metadata is discovery context; this first version does not add standards for publishers, connections, custom connectors or other resource types.

## Start here

Prefer supported standard functionality and low-code: native configuration and controls first, then Power Fx, business rules and flows. Use a low-code custom page when the native model-driven experience cannot support the task. Custom code is an exception requiring a documented reason, owner and maintenance impact, not the default implementation route.

Before review, choose meaningful [names](./naming), explain the resource's purpose, handle unsuccessful operations explicitly, and check the task with realistic data and a non-admin user. Run the relevant platform checkers and test accessibility and performance. Static CI supplements this work; it does not replace it.

| Resource | Guidance |
| --- | --- |
| Cloud flows | [Variables, contracts, error handling and performance](./cloud-flows) |
| Canvas apps | [Controls, Power Fx, forms, delegation and accessibility](./canvas-apps) |
| Model-driven apps | [Forms, views, commands and low-code custom pages](./model-driven-apps) |
| Dataverse | [Data modelling, keys, ownership and permissions](./dataverse) |
| Pull requests | [Implemented checks, local execution and merge protection](./ci-validation) |

## How to read a rule

**Must** is a team requirement. **Should** is a recommendation requiring context. Each requirement has a stable ID, independent of its position on the page. An **automated** rule has a proven source field and an implemented validator; **manual** requires review or a platform/environment test; **planned** needs further export verification before automation.

The [CI coverage table](./ci-validation#coverage) is authoritative for what is actually checked. A manual requirement must not be presented as an automatic compliance guarantee. Exceptions to a team requirement need an explicit review decision and explanation; there is no implicit legacy baseline or automatic repair.

## What changed from the original guidelines

The resource pages remove duplicated naming tables and organisation-specific instructions, distinguish platform limits from team preferences, and correct these important ambiguities:

- Compose is useful for immutable values shared by several steps; flow variables are mutable state and must be initialized globally.
- Parallel execution is not universally faster or safe. Error-handling scopes are process-dependent, not a mandatory three-scope template.
- A collection has no generic 2,000-record capacity limit. Nondelegable source queries can return incomplete data.
- Named formulas are declarative and react to dependencies; `App.OnError` does not repair a failed save.
- View names do not use number ranges. View selection, default view, form order and record sorting are different settings.
- Schema names, logical names and display names are different identities. Business Required is not a universal API constraint, and Dataverse Search is not custom SQL index management.
- For a Certificate lookup to Qualification, Append belongs on Certificate and Append To on Qualification; those privileges alone do not establish all required access.

These standards describe the intended state for existing resources too. A standards violation must be addressed through the normal solution-development process, not by renaming files or identifiers in an automation-only PR.
