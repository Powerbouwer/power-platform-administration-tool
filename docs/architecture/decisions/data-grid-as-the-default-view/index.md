---
title: "Data grid as the default view"
issue: 34
issueUrl: "https://github.com/Powerbouwer/power-platform-administration-tool/issues/34"
scope: "Core"
decisionDate: "2026-11-27"
---

# Data grid as the default view

Source: [Issue #34](https://github.com/Powerbouwer/power-platform-administration-tool/issues/34)

### Scope

Core

### Context and problem statement

PPAT is primarily built as a model-driven app. A key principle when developing the required custom pages is to preserve the look and feel of a model-driven app.

Resources are displayed on a custom page because their data comes directly from a Power Automate flow and is not available as a table in the model-driven app. Modern controls in canvas apps, including custom pages, follow the Fluent UI design language used throughout the model-driven app.

The Data grid modern control provides a structured way to display large amounts of information. Its behavior is similar to that of a standard model-driven app view. Out of the box, it supports multi-select, sorting by column, user-adjustable column widths, and keyword search across records that have already been retrieved.

The Data grid control also has a limitation: its columns cannot be generated from a collection or named formula. Each column is a subcontrol that must be configured at design time. As a result, all columns must be configured in advance, even though each resource type in Inventory has a different set of properties.


### Decision drivers

- Use out-of-the-box Power Platform capabilities.
- Configure the grid once and reuse it through configuration. Each custom page, if more than one is needed, should use the same grid with the full set of columns, while configuration controls which columns are visible.


### Considered options

- A gallery would require significant development effort and may not fully reproduce the expected grid behavior. Performance may also be a concern compared with the Data grid control.
- PCF controls or generative pages are not considered viable because they do not align with our guiding principles.


### Decision outcome

Use the Data grid control and configure the complete set of properties (columns) across all resource types. Use column configuration to control each column's visibility. See the [[ADR] Column configuration as settings](https://github.com/Powerbouwer/power-platform-administration-tool/issues/33) for more information about this configuration.


### Consequences

Positive
- Provides a structured, familiar experience that is consistent with standard model-driven app views and Fluent UI.
- Includes multi-select, column sorting, adjustable column widths, and keyword search without building these capabilities from scratch.
- Reuses one grid configuration across resource types and custom pages, with column configuration determining which properties are visible.

Negative or trade-offs
- All columns must be configured in the custom page at design time because the control cannot generate columns dynamically from configuration.
- The complete set of columns must be maintained as resource types and their properties change, even when many columns are hidden for a given resource type.
- Keyword search only searches records that have already been retrieved. It does not, by itself, search the full underlying data set.
- The grid and its column configuration must remain in sync. A property added to the configuration cannot be displayed unless its column is also configured in the control.

### Participants

@arijsdijk @miguelverweij 

### Links

_No response_
