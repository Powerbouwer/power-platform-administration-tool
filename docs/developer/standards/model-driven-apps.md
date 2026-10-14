# Model-driven apps

Start with native forms, views, navigation and controls. Use business rules with the appropriate scope and supported Power Fx command actions before considering custom code. A low-code custom page is appropriate when a task needs an experience the native pages cannot provide; it is not a PCF control or an embedded Canvas app.

Use the shared [naming conventions](./naming#model-driven-names). App display-name format is automated; form/view/internal-element naming remains manual until representative exports are verified.

## Forms

**MDA-FORM (should, manual):** create task- and role-focused forms. Use concise labels, group related information, prioritize important fields and use quick-create forms where the task benefits. Explain unfamiliar fields with descriptions.

Form ordering is a dedicated configuration setting. Manage form access and order deliberately rather than numbering names. Tab and column counts are design heuristics, not universal technical limits; assess task completion, device layout and performance.

## Views and navigation

**MDA-VIEW-NAME (must, manual):** give views meaningful names without ordering number ranges, for example `Active Certificates`, `My Active Certificates` and `Certificates Pending Review`.

The view selector sorts alphabetically, possibly within separate system/personal groups. That is distinct from the configured default view, user access and the sorting of records *inside* a view. A "My" ownership filter can belong to a managed system view; its name does not make it a personal view.

**Should:** maintain a small useful shared view set and allow personal views where appropriate. Personal user views are not necessarily exported solution components. Choose columns and filters that support the actual task, and avoid adding every available column by default.

Keep navigation focused on user tasks and roles. Hidden navigation, commands or fields are not authorization boundaries.

## Business behavior and errors

**MDA-SERVER-INTEGRITY (must, manual):** distinguish client presentation from server-side data integrity and authorization. A business rule's scope changes where it runs and which operations it supports. Hiding a control does not prevent an API write.

Prefer native validation and supported low-code mechanisms that actually meet the requirement. An asynchronous flow cannot guarantee atomic validation of a save. Custom code is an exception requiring a clear reason; this version does not introduce a JavaScript/PCF implementation guide or build pipeline.

Test successful and unsuccessful actions with non-admin roles, including inaccessible related records, validation failures and refresh behavior after changes. Present actionable errors instead of misleading success notifications.

## Sources

- [Form order and access](https://learn.microsoft.com/power-apps/maker/model-driven-apps/control-access-forms#set-the-form-order)
- [View selector ordering](https://learn.microsoft.com/power-apps/user/grid-filters-advanced#change-the-order-of-views-in-the-view-selector)
