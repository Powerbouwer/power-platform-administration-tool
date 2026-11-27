---
title: Canvas app and custom page standards
---

# Canvas apps and custom pages

These standards also apply to Canvas-based custom pages inside model-driven apps. See the [shared policy](../) for branch behavior, source coverage and low-code-first exceptions.

## Naming rules

<a id="can-001"></a>

### Canvas app display-name validation

**Partial automated check:** `CanvasApp.Name` must start with the solution publisher's customization prefix and `_`. The remaining characters must use lowercase kebab-case letters. `DisplayName` must contain readable text. Good: `ppat_inventory` or `ppat_change-viewer` / `PPAT - Inventory`. Bad: `ppat_change_viewer`, `ppat_change2`, a technical name without the publisher prefix, or a blank display name. [PPAT-001](../#ppat-001) adds the publisher prefix.

**Coverage:** The first rule reports a blank `DisplayName`. The publisher-prefix rule checks the prefix. Review the kebab-case remainder manually because Power Apps derives the technical name from the display name and appends a generated suffix (`ppat_ppattemplate_97904`, `ppat_invcloudflows_9fc3d`). Makers can't control this suffix. This part of the standard needs revision.

<a id="can-002"></a>

### Canvas screen names

**Automated check:** Screen names use words that start with uppercase letters, optionally separated by spaces. Good: `Home Screen`, `Screen Form`. Bad: `scrHome` or `screen form`. The standard doesn't require an `scr` prefix or `Screen` suffix. Screen names can include numbers as words, as in `Step 2`.

Rename screens in Studio and let Studio update references. The check reads `Screens` keys, not references inside formulas.

<a id="can-003"></a>

### Canvas control names

**Automated check:** Control names in nested `Children` use identifier characters: letters, digits, and underscores. Each name starts with a letter. Good: `btnSave`, `conMain_Form`. Bad: `Save Button`.

<a id="ppat-004"></a>

### Canvas control-prefix convention

**Automated check, team convention:** Recognized standard controls use a lowercase purpose prefix followed by an uppercase purpose.

| Control                           | Prefix                            | Example                                      |
| --------------------------------- | --------------------------------- | -------------------------------------------- |
| Text input, button, label         | `txt`, `btn`, `lbl`               | `txtSearch`, `btnSave`, `lblStatus`          |
| Gallery, form, container          | `gal`, `frm`, `con`               | `galEnvironments`, `frmDetails`, `conHeader` |
| Dropdown, combo box, radio        | `drp`, `cmb`, `rad`               | `cmbOwner`                                   |
| Toggle, date picker, slider       | `tgl`, `dtp`, `sli`               | `tglEnabled`                                 |
| Tabs, timer                       | `tab`, `tmr`                      | `tabDetails`                                 |
| Image, icon, HTML, shapes         | `img`, `icn`, `htm`, `rec`, `cir` | `icnSearch`                                  |
| Camera, barcode, add picture      | `cam`, `bar`, `pic`               | `barAsset`                                   |
| Information, pen, list, rich text | `inf`, `pen`, `lis`, `rte`        | `rteNotes`                                   |
| Canvas component                  | `cmp`                             | `cmpHeader`                                  |

Add a screen suffix when useful for uniqueness. Good: `btnSave_Form`. Bad: `Button1`.

**Exact coverage:** The rule checks whether a name follows the prefix convention, not whether each prefix matches its control type. The ruleset lists the recognized control families that occur in PPAT source: `GroupContainer`, `Gallery`, `ModernButton`, `ModernCombobox`, `ModernIcon`, `ModernInformationButton`, `ModernTabList`, `ModernText`, `ModernTextInput`, and `Rectangle`. Unrecognized controls, generated data cards, and reserved generated names (`DataCardKey`, `DataCardValue`, `ErrorMessage`, `StarVisible` with numeric/underscore suffixes) don't receive this prefix check. These are narrow exceptions, not a guarantee that the ruleset recognizes every generated name. Review unknown families, classic controls, and component definitions manually until the list includes a real example.

## Formula naming (manual review required)

| Scope          | Convention | Example           |
| -------------- | ---------- | ----------------- |
| Global state   | `gbl`      | `gblCurrentUser`  |
| Screen context | `ctx`      | `ctxLoading`      |
| Collection     | `col`      | `colEnvironments` |
| Named formula  | `nf`       | `nfTheme`         |

Local `With` record fields need meaningful names, not a mandatory `var` prefix. **The current validator doesn't check Power Fx**, including variable conventions, syntax, typing, delegation, or error handling.

## Design review (manual review required)

- Use appropriate native controls and reusable Canvas components. A Canvas component library isn't a pro-code PCF library.
- Prefer containers and flexible layouts. Test supported screen sizes, focus order, and screen-reader behavior. Modern controls don't guarantee accessibility.
- Reuse themes and provide meaningful labels that assistive technologies can interpret. Don't communicate state only through color.
- Use named formulas for declarative values and `With` for local calculations. Named formulas can recalculate. They aren't limited to static constants.
- Initialize behavior where needed. `App.Formulas` doesn't replace all mutable state or side effects in OnStart/OnVisible.
- Delegation depends on the complete formula and data source. The nondelegation limit of 500, configurable to 2,000, isn't a hard collection-capacity limit.
- Use concurrent loading only for independent work. Avoid unnecessary caching of volatile data or clearing state that users expect to retain.
- Validate input and provide explicit failure handling. Forms use OnSuccess/OnFailure. `App.OnError` isn't a generic control property. Don't disguise a connector failure as a successful `N/A` result.
- The exported App Checker SARIF may be stale. It isn't a fresh automated check.

Use PCF or script customizations only through the [ADR exception route](../#low-code-first).
