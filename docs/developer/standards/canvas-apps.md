# Canvas apps

Prefer native controls, responsive containers and supported Power Fx. Use the shared [app, screen and control conventions](./naming#app-name). Create and maintain apps in Power Apps Studio; static YAML checks are not a substitute for the designer or platform checkers.

## CANVAS-DESCRIPTION

**Must, automated presence; manual quality:** provide a nonempty app description explaining the users and business task. A missing value, whitespace or an `@xsi:nil` marker does not count as a description.

## State and formulas

**CANVAS-STATE (should, manual):** choose the narrowest appropriate state scope. Use `With` for local calculation, context variables for screen state and global variables only for genuinely shared mutable state. Collections are local data structures, not automatically complete replicas of a source.

Use named formulas for declarative values and calculations that react to dependencies, not only constants. Do not move mutation-heavy initialization into `App.Formulas`; distinguish declarative calculations from behavior formulas. Use readable expressions, format them in Studio and explain only non-obvious decisions.

Use reusable components and component libraries when their ownership and update process are clear. Avoid duplicating business logic across many controls.

## Data and delegation

**CANVAS-DELEGATION (must, manual/platform check):** verify delegation for the actual connector, function and complete expression. A nondelegable source query normally processes only the configured data-row limit (500 by default, configurable to 2,000), potentially giving incomplete results.

This is not a general 2,000-record collection capacity limit. A collection can hold more records, but collecting a source does not establish completeness. Test with data beyond the configured limit and realistic filters. Do not use a context-free blacklist of functions or assume that an empty result proves the absence of matching records.

**Should:** filter at the source, retrieve only what the task needs and avoid repeated queries from many controls. Keep loading and empty states distinct from errors.

## Saves and errors

**CANVAS-SAVE (must, manual):** show success only after a confirmed save. For forms, use the appropriate `OnSuccess` and `OnFailure` paths; for other mutations, handle the operation's failure explicitly with supported error handling. Preserve user input when retrying is appropriate.

`App.OnError` can report unhandled errors but does not undo a failed operation or make it successful. Avoid broad fallbacks that replace a failed essential query with an empty collection and hide the problem.

## Usability and accessibility

**CANVAS-ACCESSIBILITY (must, manual/platform check):** test keyboard navigation, focus order, accessible labels, contrast and screen reader behavior. Use plain-language screen names; icon-only actions need understandable labels.

**Should:** design responsive layouts for the actual devices, make primary actions discoverable, and distinguish loading, no-data and failure states. Modern controls can be useful but still require compatibility and accessibility checks. Test the full task with representative users and data, not only the initial screen.

## Sources

- [Readable names](https://learn.microsoft.com/power-apps/guidance/coding-guidelines/code-readability)
- [Delegation](https://learn.microsoft.com/power-apps/maker/canvas-apps/delegation-overview)
- [App.Formulas and App.OnError](https://learn.microsoft.com/power-platform/power-fx/reference/object-app)
