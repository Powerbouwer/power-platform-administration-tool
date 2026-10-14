# CI validation

The central **Power Platform PR quality** workflow reads labels, discovers the active solution and produces the stable **Power Platform standards** check. Existing development/project/documentation scope checks remain separate.

## Scope and severity

Resource validation applies to PRs labeled `dev`. The active solution is selected **only from changed paths** under `solutions/{unique name}/`, including previous rename paths and deleted files, never from the source branch.

Exactly one changed solution directory selects that solution. All its supported solution components are checked, including unchanged resources. Other solutions are not read or allowed to block this run. Component membership comes from the native `SolutionComponents.Component[].@path` manifest.

No changed solution directory means explicitly **not applicable**, including docs-only `dev` PRs. Multiple directories are an ambiguous selection and fail execution without scanning both. A fully removed solution is reported as **deleted** rather than replaced with another solution.

For an exact target branch of `main`, rule and coverage findings are errors and the validator exits nonzero. For every other target, those findings are warnings and the validator succeeds. Checkout, API, selection, configuration and runner failures remain execution errors on all branches. Unsupported data must never appear as a successful compliance check.

## Coverage

| ID / topic | Status | Source |
| --- | --- | --- |
| [FLOW-NAME](./naming#flow-name) | Automated | `Workflow.@Name` in `workflow.yml` |
| [APP-NAME](./naming#app-name) | Automated | `CanvasApp.DisplayName`; `AppModule.LocalizedNames.LocalizedName.@description` |
| [FLOW-VAR-NAME](./naming#flow-var-name) | Automated | `InitializeVariable.inputs.variables` in JSON `properties.definition.actions` |
| [FLOW-VAR-SCOPE](./cloud-flows#flow-var-scope) | Automated | Action nesting, including else/cases/default and loop bodies |
| [CANVAS-DESCRIPTION](./canvas-apps#canvas-description) | Automated presence | `CanvasApp.Description`, not a name or formula |
| [CANVAS-SCREEN](./naming#canvas-screen) | Automated format | `Screens` keys in unpacked `Src/*.pa.yaml` |
| [CANVAS-CONTROL](./naming#canvas-control) | Automated for mapped types | `Control` type/version and named `Children` |
| [CANVAS-UNIQUE](./naming#canvas-unique) | Automated for screens/controls | Full app screen/control traversal |
| Dataverse tables, columns, choices, roles, relationships | Planned | Obtain and verify native exports first |
| MDA forms/views and internal names | Planned | Obtain and verify entity subcomponent exports first |
| Flow description, child-flow contracts, concurrency, retries, filters | Manual / future | No universal reliable rule established |
| Power Fx variable scopes, named formulas and delegation | Manual/platform check | No Power Fx interpreter or regex semantic claims |
| Effective permissions, UX, accessibility and performance | Manual/platform/environment check | Source alone does not establish correctness |

Only the verified native YAML layout is supported. Classic XML solutions and shared environment-bound component roots are not silently accepted as the repository's solution-bound layout.

## SOURCE-COVERAGE

The validator reports malformed/missing supported sources, unlisted resource directories, duplicate YAML/JSON keys, unverified control types, component-definition namespaces and binary-only Canvas apps as explicit coverage findings. It does not execute source content, instantiate YAML object tags or follow a source path/symlink outside its solution. YAML aliases/merges and custom tags are not supported; mapping keys must be text, with implicitly typed words quoted to prevent key collisions. Inspection is limited to one YAML document, 8 MiB per source file and bounded nesting.

Dataverse components are counted and reported as not yet supported when present. Their absence is normal and does not fabricate a violation. Other resource types such as connection references and custom connectors are outside scope and receive no new naming/description rules.

Cloud flows use `Workflow.JsonFileName`, resolved relative to the selected solution root, to read `properties.definition`. A localized-name `@description` or an action note is not a flow-level description. The `manual` / `PowerAppV2` trigger in the inventory-search fixture is not classified as a child flow.

## Run locally

Use Ruby 3.1 or newer with YAML/Psych and JSON already available. The validator uses no additional npm packages, Ruby gems, Bundler or installation/build step. Ruby is required only to run these local checks; the existing npm/VitePress tooling remains for docs.

Create a JSON file containing changed paths or the GitHub PR-files response (including `previous_filename` for renames). For example:

```json
[
  {
    "filename": "solutions/ppat_core/canvasapps/ppat_ppattemplate_97904/canvasapp.yml",
    "status": "modified"
  }
]
```

From the repository root on Windows:

```powershell
ruby scripts\standards\test_validate.rb
ruby scripts\standards\validate.rb --root . --base main --changed-files changed-files.json --report standards-report.json --summary standards-summary.md
```

Use the actual target branch in `--base`, not the source branch. These commands report problems; they never modify solutionresources. Remove local report/input files after use and do not commit sensitive PR data.

Exit codes: `0` for no errors, warnings-only, not applicable or deleted; `1` for main-target standards/coverage errors; `2` for execution/selection failures. Findings are deterministically sorted and include rule, solution, resource identity, file/property, expected/found, remedy and a docs reference.

## Trusted execution and tooling changes

The central workflow uses `pull_request_target` so the workflow, validator and policy come from the trusted PR base. It checks out the exact PR head separately **as input data only**, with persisted Git credentials disabled. It never executes PR-head scripts, builds apps, or loads PR policy.

Label writing is isolated to the prepare job. Fork PRs are not automatically labeled, but a manually labeled fork can be inspected read-only. Actual labels are read after labeling in the same orchestration because `GITHUB_TOKEN`-created labels do not start another `labeled` workflow.

The separate **Standards tooling tests** `pull_request` workflow tests proposed validator changes with read-only permissions and no secrets. This is not another label-dependent resource workflow. Policy changes become active only after reviewed merge to the relevant base.

Events cover opening, commits, reopening, ready-for-review, label changes and editing (including target changes). A final gate fails when preparation/validation fails or is cancelled. API results must be complete and match the expected head/base; partial or stale data is not a valid assessment.

## Rollout and main protection

The workflow must first be reviewed and deployed to the relevant PR bases. Existing release/sprint branches can have older automation: the old sprintbranch regex does not recognize `core/v1.0.0/spr-70`. Synchronize automation through a controlled maintainer process before relying on its checks; do not change solutionresources to deploy CI.

After deployment, use controlled PRs to confirm warnings on a non-main target, errors on main, label handling, retargeting and the explicit non-applicable outcome. Register **Power Platform standards** and then add it as a required status check in the existing `main-protection` ruleset, preserving existing rules and bypass policy. Consider strict up-to-date checks to avoid trusting an outdated base.

**A red annotation or workflow does not itself block merge.** Main protection is not complete until the required check is configured and an actual missing/failed check prevents merge. Do not require an undeployed check: that would strand unrelated PRs. If maintainer permissions or deployment are unavailable, report this rollout step as pending rather than claiming enforcement is active.

## Fixture provenance

The inventory-search fixture preserves the actual `workflow.yml` and JSON structure from `core/v1.0.0/spr-70`, component `ca27d5d6-2bc3-f111-a05c-70a8a507ac5b`. Its existing two-part name deliberately produces `FLOW-NAME`; fixture status is not a legacy exception.

Canvas metadata and the nested screen/control excerpt come from `ppat_ppattemplate_97904`; model-driven display-name metadata comes from `ppat_PowerPlatformAdministrationTool`. Tests supplement these native examples with generated edge cases for multiple solutions/resources, nesting, parse errors, unsafe references and branch severity. Synthetic cases do not prove support for other native export formats.
