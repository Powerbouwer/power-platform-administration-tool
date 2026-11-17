---
title: Power Platform resource standards
---

# Power Platform resource standards

These standards cover resources under `solutions/`. They describe naming conventions and engineering guidance. Spectral automatically checks rules marked **automated check** (`npm run lint:spectral`). Reviewers must assess the rest. The check doesn't confirm that an app is secure, usable by people with disabilities, fast, or functionally correct.

| Resource                     | Standard                                          |
| ---------------------------- | ------------------------------------------------- |
| Cloud flows                  | [Names and review guidance](./cloud-flows/)       |
| Model-driven apps            | [Names and review guidance](./model-driven-apps/) |
| Canvas apps and custom pages | [Names and review guidance](./canvas-apps/)       |
| Dataverse                    | [Names and review guidance](./dataverse/)         |

All documentation pages use a topic directory containing `index.md`.

## Low-code first

Prefer standard controls, native model-driven configuration, custom pages, Power Fx, declarative commands, business rules and solution-aware cloud flows. Choose the simplest supported mechanism that meets the actual requirements.

PPAT introduces PCF controls, .NET plug-ins, custom workflow activities, or JavaScript/TypeScript web resources **only when necessary and supported by an approved architecture decision record (ADR)**. This also applies to third-party pro-code dependencies. A Canvas component or component library isn't a PCF control. Built-in Microsoft platform functionality isn't a PPAT customization.

An exception must explain:

- why native or low-code alternatives can't meet the requirement.
- the smallest necessary customization and its security, licensing, and deployment impact.
- who owns maintenance and testing, and how the team could replace it later.

Don't replace transactionally enforced server-side validation with an asynchronous flow. Don't treat hidden UI as authorization to avoid pro-code. These are architecture review decisions, not automatic lint rules.

Use the [existing architecture decision process](../../architecture/). These decisions use GitHub issues of type `ADR`. Closing an issue as completed automatically creates a documentation PR. Don't close a draft to publish an unapproved decision. Record low-code-first and naming-automation decisions through this process. This change doesn't create or close issues.

## General conventions

- Use readable English names that describe purpose. Keep terminology consistent throughout the solution.
- Separate technical names, internal identifiers, and user-facing labels. Don't rename immutable schema names to fix a display-label issue.
- The publisher prefix is `ppat`. Start custom solution and app technical names with that prefix and an underscore. Don't rewrite platform-generated identities or external dependencies.
- Give resources meaningful descriptions where supported. Explain non-obvious decisions, rather than commenting every action.
- Keep configuration environment-independent. Use connection references and environment variables where appropriate. Ordinary text environment variables don't store secrets.
- Keep development current values and credentials out of distributed source. Environment-independent product defaults can be valid.
- Build from unmanaged source. Deploy managed solutions downstream. An unmanaged development download doesn't permit unmanaged production customization.

The [description rule](#gen-001) checks only whether a description exists. Review description quality, secrets, configuration values, dependencies, and deployment state manually.

## How continuous integration works

The pull request validation workflow classifies the entire PR diff, including both sides of renames. It assigns `dev` to paths under `solutions/`. It assigns `docs` to paths under `docs/`, including `.vitepress/`. It assigns `project` to all other paths, including `.github/`, root files, `package.json`, and `package-lock.json`.

Labels describe the changed paths independently of validation. Package files configure shared npm tooling but receive only the `project` label. VitePress configuration under `docs/.vitepress/` remains docs-only. Other root files, such as `.gitignore`, are project-only.

The single validation workflow, `pr-checks.yml`, synchronizes the `dev`, `docs`, and `project` labels for same-repository PRs and removes stale category labels. The **Validation result** job classifies changes and runs the checks, using step-level `if` conditions instead of calling other workflows. It checks out the source and installs npm dependencies once. A failed check stops subsequent steps and fails the job. A separate labeling job has write permissions and still runs if validation fails after classification.

Every valid PR runs `npm ci`, `npm run audit`, and `npm run lint`. The lint command checks vulnerability documentation, formatting, prose, JavaScript, and solution naming in sequence and stops on the first failure. The shared `scripts/classify-scope.mjs` script reads the changed paths for PR validation and push builds.

Pull requests can change multiple solutions. All checks use the merge-candidate commit. Spectral checks all solutions on every valid PR, not only changed files.

| Situation                                                                      | Behavior                                                                                                            |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| Target `main`                                                                  | The check reports naming findings as errors and blocks the merge, including for pre-existing findings               |
| Other supported solution target                                                | Naming errors also fail the check                                                                                   |
| Documentation changes                                                          | Repository-wide lint runs, including Prettier and Vale                                                              |
| Project/configuration changes                                                  | Repository-wide lint runs, including Spectral                                                                       |
| Package files changed                                                          | The workflow adds only the `project` label and runs the same audit and lint checks                                  |
| Solutions and package files changed                                            | The check rejects `dev` + `project`. Update shared dependencies in a separate PR                                    |
| Mixed categories                                                               | All applicable validators run. You can combine `docs` with `dev` or `project`                                       |
| Both `dev` and `project` changed                                               | The workflow syncs labels and fails validation before running specialized checks                                    |
| No changed paths                                                               | Audit and repository-wide lint still run. Solution policy checks skip                                               |
| Invalid YAML, missing required source files, broken ruleset or tooling failure | The check fails in either mode. This indicates invalid input or a tooling problem, not a successful naming analysis |
| Unsupported component type                                                     | Spectral doesn't check this component because no rule applies. This doesn't cause a failure                         |
| Unknown YAML root shape                                                        | No format rule. Naming selectors may not match it                                                                   |
| More than one changed solution                                                 | Each changed solution gets its own build and pre-release after merging to `main`                                    |

Retargeting a PR reruns the policy. This naming check doesn't replace release packaging validation.

Spectral uses the root ruleset for all solutions. Naming errors, invalid input, and tooling errors fail the check for every target. PR checks classify changes by file path, not branch name. Branch naming and branch/version checks no longer apply.

**A failing workflow only prevents merging if the repository ruleset requires the fixed check.** Maintainers must approve and configure this protection in repository settings. This implementation doesn't change those settings.

## Automated checks (Spectral)

The root `.spectral.yaml` is the only validator. It defines declarative Spectral rules with built-in functions such as `pattern` and `schema`. It doesn't use custom functions or scripts. Spectral reads native Git source and reports findings. It doesn't format or rewrite solution files.

### Run locally

Use the repository's configured Node.js version and locked npm dependencies. From the repository root:

```powershell
npm ci
npm run lint:spectral
```

The PR workflow runs the same command as part of `npm run lint`. Each finding identifies the file, location, severity, rule ID, issue and expected convention, and property path. Exit code `0` means no errors. The command can still report warnings. Exit code `1` means at least one error, and `2` means Spectral couldn't run, for example, because of a broken ruleset. Spectral reports invalid YAML as an error. The recommended VS Code Spectral extension uses the same ruleset and shows findings in the editor.

Fix findings in the maker tools and sync through native Git integration. Don't edit generated source to satisfy a rule.

### Scope

The command reads JSON and YAML files under `solutions/`, including `.yml`, `.yaml`, and `.pa.yaml` files. It excludes files without these extensions, such as images without a file extension. Spectral reports parsing errors in the files it reads, even when no rule applies. Every rule is `off` by default. When configured, `overrides` enable rules only for the component files below. Each `given` selector starts at the component's root key, such as `$.CanvasApp` or `$.Screens`.

| Component                  | File pattern                                               | Rules                               |
| -------------------------- | ---------------------------------------------------------- | ----------------------------------- |
| Solution                   | `solutions/*/solutions/*/solution.yml`                     | NAM-001, NAM-002, PPAT-001, GEN-001 |
| Publisher                  | `solutions/*/publishers/*/publisher.yml`                   | NAM-001, NAM-002, GEN-001           |
| Model-driven app           | `solutions/*/appmodules/*/appmodule.yml`                   | NAM-001, NAM-002, PPAT-001          |
| Sitemap                    | `solutions/*/appmodulesitemaps/*/appmodulesitemap.yml`     | NAM-002, PPAT-001, MDA-001, MDA-002 |
| Canvas app                 | `solutions/*/canvasapps/*/canvasapp.yml`                   | PPAT-001, CAN-001, GEN-001          |
| Canvas screens             | `solutions/*/canvasapps/*/*_DocumentUri/Src/[!_]*.pa.yaml` | CAN-002, CAN-003, PPAT-004          |
| Cloud flow (`Category: 5`) | `solutions/*/modernflows/*/workflow.yml`                   | NAM-002, CFL-001, PPAT-002          |

Rules don't cover other component types, `_EditorState.pa.yaml`, duplicated `Controls/*.json`, or flow-definition JSON. The command doesn't read cached SARIF or binary files without extensions.

Rule-ID prefixes such as `NAM-`, `GEN-`, `PPAT-`, `CAN-`, `CFL-`, `MDA-`, and `DV-` group rules in documentation. They aren't the publisher prefix `ppat_` or Canvas control prefixes such as `btn`.

### Limitations

- Spectral checks one file at a time and can't relate files. PPAT-001 therefore uses the fixed prefix `ppat` instead of reading `publishers/<publisher>/publisher.yml`.
- The current solution contains no table, column, relationship, form, view, environment variable, or connection reference export. The team hasn't verified file structures for those components, so reviewers must assess them manually.
- Power Fx (formulas, variable and collection names), flow action and trigger names, and the meaning or quality of names and descriptions are manual review. Solution Checker is outside scope.

## Shared rule catalog

<a id="nam-001"></a>

### Technical names for solutions and apps

**Automated check:** For a solution, publisher, or model-driven app, `UniqueName` must start with a letter and contain only letters, digits, and underscores. Good: `contoso_inventory`. Bad: `Inventory App`. Fix the authoring name when you create the resource. Don't casually change an established immutable name.

<a id="nam-002"></a>

### Localized resource labels

**Automated check:** When a resource has localized names, each `LocalizedName` needs a non-whitespace `@description` label, whether the export uses one object or an array. Good: `Inventory`. Bad: an empty or nil label. This property contains the localized **name**, not a resource description. Supply a missing label in the resource designer.

<a id="ppat-001"></a>

### Publisher prefixes for solution and app names

**Automated check:** Start solution, app, and sitemap technical names with the publisher prefix and `_`. Good: `ppat_Inventory`. Bad: `new_Inventory`. Spectral can't read `Publisher.CustomizationPrefix` from another file, so `.spectral.yaml` fixes the prefix as `ppat`. Update it there if the publisher changes. The rules check only solution `UniqueName`, model-driven app `UniqueName`, sitemap `SiteMapUniqueName`, and Canvas app `Name`. They don't check generated app-element names or Microsoft resource GUIDs.

<a id="gen-001"></a>

### Resource descriptions

**Partial automated check, warning:** Solutions, publishers, and Canvas apps need a description. The rule reports an empty value or `xsi:nil`. Reviewers must assess the description's quality. Add the description in the maker portal. The rule doesn't cover other components. Connection references omit empty descriptions from exports, and the team hasn't verified descriptions in flow or model-driven app exports.

## Maintaining rules

Change a rule together with its documentation and good/bad examples. Keep its ID stable and provide a documentation anchor. In `.spectral.yaml`, define the rule once under `rules` with `severity: "off"` and a `given` selector rooted at the component's top-level key. Enable it with `error` or `warn` in the `overrides` entry for that component's file pattern. Use only built-in Spectral functions. Don't add custom functions or scripts. Test the rule with real exported source and good/bad examples, then run `npm run lint:spectral`. Label a rule **automated check** only after you implement it. Label anything else **manual review required**.

The lockfile pins this dependency. When maintainers introduced it, npm reported advisories in Spectral's transitive glob tooling and the existing documentation toolchain. No automatic fix was available. CI uses fixed local patterns and runs PR code without elevated permissions. This limits exposure, but it doesn't remove the advisories. Maintainers must track upstream fixes. This change doesn't include unrelated upgrades or silent audit suppression.
