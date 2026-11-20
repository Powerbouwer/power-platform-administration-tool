---
title: Model-driven app standards
---

# Model-driven apps

Follow the [shared naming and low-code-first policy](../). Prefer native forms, views, navigation, and declarative commands. Custom pages can provide task-focused workspaces without PCF or script libraries.

## Naming rules

The shared [NAM-001, NAM-002 and PPAT-001 rules](../#shared-rule-catalog) cover app identity and localized labels.

<a id="mda-001"></a>

### Model-driven app sitemap name

**Automated check:** `AppModuleSiteMap.SiteMapUniqueName` is a technical identifier that starts with a letter and contains only letters, digits, and underscores. Good: `ppat_Administration`. Bad: `Administration Sitemap`. The publisher-prefix rule also checks the solution publisher's technical prefix and `_`.

<a id="mda-002"></a>

### Model-driven app sitemap title labels

**Automated check:** Sitemap `Titles.Title` labels must contain text and can't exactly match designer placeholders such as `Area1`, `Group1`, or `SubArea1`. The check accepts one title or a localized list.

Good: `Administration`, `My Work`. Bad: `Area1`. Rename the visible title in the designer. You don't need to change a generated area/group ID. The check doesn't judge all wording or enforce one area per persona.

## Naming guidance (manual review required)

| Element               | Convention                               | Example                        |
| --------------------- | ---------------------------------------- | ------------------------------ |
| Form                  | Table - Purpose                          | `Environment - Main`           |
| View                  | Table - Purpose                          | `Environment - Active`         |
| Tab internal name     | `tab_` plus purpose                      | `tab_details`                  |
| Section internal name | `sec_` plus purpose                      | `sec_ownership`                |
| Subgrid internal name | `subgrid_` plus table                    | `subgrid_environments`         |
| Custom command        | `cmd_` plus table and purpose            | `cmd_environment_refresh`      |
| Fluent icon resource  | Publisher prefix once, then icon purpose | `ppat_ic_fluent_calendarClock` |

Use short readable labels rather than exposing internal prefixes. Don't add mandatory 100/200/300 number ranges to forms or views. The first ruleset doesn't cover native form/view export internals or icon naming.

## Design review (manual review required)

- Keep layouts task-focused and navigation understandable. Review tab/column counts rather than enforcing arbitrary universal limits.
- Views show useful columns, ordering, and filtering. An intentional "All" view is valid. Product or governance policy determines whether to require personal views.
- Use labels that assistive technologies can interpret and a consistent icon style. Don't rely on color or hidden controls for meaning or security.
- Avoid redundant requests and measure actual load times. Source metadata doesn't prove performance.
- Enforce authorization server-side. Hiding a command or sitemap item doesn't enforce access control.
- Use native business rules when their supported scope and actions meet the requirement. Form-only logic doesn't guarantee server-side enforcement.
- If an ADR approves JavaScript, use supported `formContext` APIs, documented event registrations, and the required execution context. Don't use deprecated `Xrm.Page` or unsupported DOM manipulation.

PCF, plugins, and script-library development aren't part of the default PPAT implementation approach or this validator. An approved exception must include its own maintenance and testing plan.
