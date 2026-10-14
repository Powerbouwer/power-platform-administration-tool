# Naming

Use meaningful English names in new PPAT resources. These are team conventions, not Microsoft platform restrictions. Keep names consistent with the business language and distinguish editable display names from technical identifiers used by formulas, expressions and dependencies.

## FLOW-NAME

**Must, automated:** use `Module - Domain/Process - Purpose` for cloud flow display names, with the ASCII separator ` - ` and exactly three nonempty, trimmed parts. The domain can be a process rather than a table, for example `PPAT - Inventory - Search Resources`.

For a deliberately designed child flow, use four parts: `Module - Child Flow - Domain/Process - Purpose`, for example `PPAT - Child Flow - Certificates - Retrieve Recipients`. CI checks the name format, not whether the flow is actually a child flow. A trigger named `manual` does not establish that classification.

`PPAT - Search Inventory` is the existing export used as a parser fixture; it does **not** meet the new three-part convention. Keeping a real fixture does not grant a policy exception or authorize renaming the live flow.

## APP-NAME

**Must, automated:** use `Module - Purpose` for Canvas and model-driven app display names, with exactly two nonempty, trimmed parts, for example `PPAT - Administration` or `PPAT - Template`. Validate display names, not generated schema names such as `ppat_ppattemplate_97904`. For model-driven apps, the check applies to every exported localized display name.

## FLOW-VAR-NAME

**Must, automated:** start a flow variable with the prefix for its declared type, followed by a PascalCase purpose. No spaces or underscores.

| Declared type | Prefix | Example |
| --- | --- | --- |
| String | `str` | `strCertificateId` |
| Integer | `int` | `intCertificateCount` |
| Float | `flt` | `fltTotalAmount` |
| Boolean | `bool` | `boolIsEligible` |
| Array | `arr` | `arrRecipients` |
| Object | `obj` | `objQueryResult` |

There is no separate native date variable type. Use a meaningful string name such as `strSubmittedOn` and document the format and time zone. Do not use `var`, `dt` or a different prefix for a flow variable.

## CANVAS-SCREEN

**Must, automated format; manual meaning:** use plain-language screen names with spaces, starting each word with an uppercase letter and ending in `Screen`, for example `Home Screen` or `Certificate Form Screen`. Avoid `scrHome` and cryptic abbreviations: screen readers announce the name.

## CANVAS-CONTROL

**Must, automated for mapped types:** use a lowercase type prefix and a PascalCase purpose, for example `btnSaveCertificate`. An optional underscore suffix such as `_CertificateForm` or `_1` can preserve uniqueness; it is not mandatory for every control.

| Control family | Prefix | Control family | Prefix |
| --- | --- | --- | --- |
| Text input | `txt` | Button | `btn` |
| Label / modern text | `lbl` | Gallery | `gal` |
| Form | `frm` | Data card | `crd` |
| Dropdown | `drp` | Combo box | `cmb` |
| Radio | `rad` | Toggle | `tgl` |
| Date picker | `dtp` | Slider | `sli` |
| Container | `con` | Group | `grp` |
| Tab list | `tab` | Timer | `tmr` |
| Image | `img` | Icon | `icn` |
| HTML text | `htm` | Rectangle | `rec` |
| Circle | `cir` | Camera | `cam` |
| Barcode reader | `bar` | Add picture | `pic` |
| Information button | `inf` | Pen input | `pen` |
| List box | `lis` | Rich text editor | `rte` |
| Checkbox | `chk` | Table | `tbl` |

The supported exported control types are explicitly mapped in `scripts/standards/policy.yml`. A new type needs a verified mapping; CI reports missing coverage rather than guessing its prefix.

## CANVAS-UNIQUE

**Must, automated:** control and screen names must be unique across the app. A suffix is useful when otherwise identical controls occur on different screens. Component-definition namespaces require separate export verification; they are not silently treated as ordinary screens.

## Canvas formula names

**CANVAS-STATE-NAME (must, manual):** use scope-specific prefixes followed by a PascalCase purpose: `gbl` for global variables, `ctx` for screen context variables, `var` for local names in `With`, `col` for collections and `nf` for named formulas. Components use `cmp`. These are PPAT choices and deliberately differ from some Microsoft examples. Do not apply flow type prefixes to Canvas formula variables.

The YAML validator does not interpret Power Fx to identify variable declarations, scope or delegation.

## Model-driven names

**MDA-ELEMENT-NAME (must, manual / planned automation):** forms use `Table - Purpose`, for example `Certificate - Main` and `Certificate - Quick Create`. Views use natural descriptive names such as `Active Certificates`, `My Active Certificates` or `Certificates Pending Review`. Do not add number ranges for ordering.

Internal tab, section and subgrid names use `tab_purpose`, `sec_scope` and `subgrid_tablename`, for example `tab_details`, `sec_ownership` and `subgrid_certificates`. Their display labels remain user-friendly. A view's purpose does not determine whether it is a system or personal view.

## Dataverse names

**DATAVERSE-NAME (must, manual / planned automation):** tables have business-friendly singular and plural display names, for example `Certificate` / `Certificates`. Columns use concise labels such as `Expiration Date`; descriptions explain their meaning. Custom schema names use the actual publisher prefix exactly once and a PascalCase purpose, while logical names use the platform-generated lowercase identity. For example, schema name `ppat_Certificate` and logical name `ppat_certificate`.

Use a lookup label for the related concept, such as `Qualification`; do not confuse a relationship schema name with the lookup column's name. Alternate keys describe the uniqueness rule, business rules use `Table - Purpose`, and security roles use `Module - Role`. Generated/system components are not manually renamed to fit a custom naming convention.

Technical names and IDs are dependency-bearing identities. Correcting them may require a migration; changing the export filename is not a migration.
