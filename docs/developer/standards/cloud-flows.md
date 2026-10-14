# Cloud flows

Use the shared [naming conventions](./naming#flow-name). Prefer a small flow with a clear purpose and supported connector operations over unnecessary custom code.

## FLOW-DESCRIPTION

**Must, manual:** describe the purpose, trigger, inputs/outputs, important assumptions and expected failures in the flow's details. Add action notes where they explain non-obvious logic; do not restate every action.

A YAML `LocalizedNames...@description` can contain a display name, not a flow description. An action's JSON `description` is also not the flow-level description. The current export does not establish a reliable flow-level description field, so CI does not claim to check it.

## Triggers and actions

**FLOW-ACTION-NAME (should, manual):** give triggers and actions operational names with useful context, such as `Recurrence | Every 10 Minutes` or `List Rows | Certificates Pending Review`. Describe Dataverse change types and relevant filters accurately. Do not force an exact original connector label: labels depend on designer language and export normalization.

Technical action keys are referenced by expressions and `runAfter`. Rename through the supported designer and check dependencies; do not rewrite keys in exported files merely to satisfy a cosmetic convention.

## FLOW-VAR-SCOPE

**Must, automated:** initialize variables at the top level of the flow, outside scopes, conditions, switches and loops. Variables are global mutable state; use the [declared-type prefix](./naming#flow-var-name).

Use Compose for immutable values and transformations, including values reused by several actions. Use variables when subsequent actions actually change the value. Prefer existing action outputs over another API request for information already retrieved.

Nested initialization and variable naming are checked structurally, including condition else branches, switch cases/default and loop bodies. CI does not prove correctness of expressions or shared-state concurrency.

## Errors and completion

**FLOW-ERROR (must, manual):** distinguish a successful operation, an optional empty result and an actual failure. Configure `runAfter` deliberately for failure and timeout paths; do not silently convert an essential failed action into a success-shaped result.

**Should:** use Try/Catch/Finally-style scopes where the process needs recovery and cleanup. They are not mandatory scaffolding for every flow. Retry transient transport failures where safe; do not blindly retry invalid input, authorization failures or non-idempotent writes. Report enough context and correlation information for recovery without exposing complete sensitive payloads.

Check that the final run status and any response accurately reflect handled and unhandled failures. Test connector failure, timeout, empty results and partial writes as well as the happy path.

## Child-flow contracts

**FLOW-CHILD-CONTRACT (must, manual):** document the supported input/output contract and calling expectations. Create parent and child flows in the required solution context and configure connections according to the platform's child-flow requirements.

A manually named trigger or a Request trigger alone is not proof of a child flow. The existing inventory-search flow uses `kind: PowerAppV2` and responds to an app. Verify supported input types instead of promising generic object/array inputs for every trigger.

## Performance and reliability

**FLOW-PERFORMANCE (should, manual):** filter at the source, retrieve only necessary columns, and configure paging based on expected volumes and connector limits. Measure real workloads before changing retry, timeout or concurrency settings.

Parallelize only when order, side effects and shared state permit it. Shared variable mutation inside a concurrent loop can produce incorrect results. Do not universally enable maximum concurrency. Make repeatable operations idempotent or explicitly handle duplicates and partial completion.

## Sources

- [Naming](https://learn.microsoft.com/power-automate/guidance/coding-guidelines/use-consistent-naming-conventions)
- [Variables and concurrency](https://learn.microsoft.com/power-automate/create-variable-store-values)
- [Child flows](https://learn.microsoft.com/power-automate/create-child-flows)
