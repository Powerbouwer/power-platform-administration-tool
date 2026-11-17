---
title: "Developer Guidelines"
layout: doc
---

# Developer guide

This guide describes how to prepare a development environment and contribute to PPAT through Power Platform native Git integration. Each developer works from a separate developer tenant and environment so that development work remains isolated.

## Feature and improvement work

Use the [Feature / Improvement issue form](https://github.com/Powerbouwer/power-platform-administration-tool/issues/new?template=feature.yml) for both initial ideas and defined product development work. The form uses the `feature` issue type.

Describe the problem or reason for change and the desired outcome. The audience, target solution, acceptance criteria, and technical context are optional when you first submit the issue. Refine the scope, constraints, and acceptance criteria in the issue as the proposal develops. You don't need a separate issue template.

Use the [Feature / Improvement PR checklist](https://github.com/Powerbouwer/power-platform-administration-tool/blob/main/.github/PULL_REQUEST_TEMPLATE/feature.md) to review the delivered result, agreed scope, applicable standards, verification, and documentation. Keep the detailed explanation and agreements in the issue rather than repeating them in the PR.

Use the Bug, Documentation, ADR, or Project forms for problems in existing behavior, documentation changes, architecture decisions, or repository/tooling/process work respectively.

## Resource standards

Follow the [Power Platform resource standards](./standards/) when building solution components. The naming validator checks all solutions, not just changed resources. Naming errors block pull requests regardless of the target branch. Power Fx analysis and Solution Checker are outside this validator.

## Documentation development

Use the repository's configured Node.js version and run `npm ci` from the repository root. The root package owns VitePress and the documentation scripts, so you don't need a separate installation in `docs`.

Run these commands from the repository root:

```sh
npm run docs:dev
npm run docs:build
npm run docs:preview
```

Build before starting the preview server. VitePress writes the generated site to `docs/.vitepress/dist`.

The root package provides the shared Prettier setup. Check repository formatting with:

```sh
npm run lint:prettier
```

The PR workflow runs this formatting check as part of `npm run lint`. Prettier respects the repository's ignore configuration. The documentation build is a separate command.

## JavaScript standards

Use the repository's configured Node.js version and run `npm ci` from the repository root to install the locked development tools.
ESLint checks all maintained `.js`, `.mjs`, and `.cjs` files, including tooling under `.github`, documentation loaders, and JavaScript in solutions.
The configuration excludes generated VitePress output/cache, `node_modules`, and naming reports.
ESLint doesn't check TypeScript, Vue, JavaScript embedded in Markdown, or inline JavaScript in workflow YAML.

The flat configuration in `.github/eslint/eslint.config.mjs` combines recommended JavaScript error detection with `eqeqeq`, `prefer-const` and explicit formatting rules through `@stylistic`:

- Two spaces for indentation.
- Single quotes, allowing double quotes when they avoid escaping.
- Required semicolons.
- Trailing commas for multiline lists.
- Consistent spacing and no trailing whitespace.

Run these commands from the repository root:

```sh
npm run js:lint
npm run js:lint:fix
```

The second command applies safe automatic fixes. Review the diff and resolve any remaining errors manually.
Because the configuration lives under `.github/eslint` rather than in the root, direct ESLint invocations must include `--config .github/eslint/eslint.config.mjs`.
The npm scripts and the recommended VS Code ESLint extension already use that configuration. This setup doesn't enable automatic fixes on save.

`.mjs` files use ES modules and `.cjs` files use CommonJS.
Plain `.js` files use script mode, except for `.github` tooling, which uses CommonJS.
The configuration enables Node.js globals only for `.github` tooling and documentation `.mjs` loaders.
If browser or Dataverse scripts need platform globals, declare them in a narrowly scoped configuration block. Don't enable Node.js globals or disable undefined-variable checks for all files.

Every valid pull request runs `npm run lint`, which includes `npm run lint:eslint`.
The validator checks the entire JavaScript scope, not just changed files, and errors or warnings fail the shared **Validation result** check.
Require this check in branch protection to prevent merges. The lint setup doesn't change repository protection settings.

## Prerequisites

Before starting, make sure that you have:

- A developer tenant with a developer environment.
- A managed developer environment. Dataverse Git integration requires a managed environment.
- The System Administrator security role in the Dataverse environment.
- An Azure subscription in the same Microsoft Entra tenant as the Dataverse environment.
- Permission to create an Azure Key Vault and assign roles.

## Set up Git integration

The setup uses the existing PPAT GitHub App:

| Setting             | Value                                                                                                                 |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| GitHub organization | `Powerbouwer`                                                                                                         |
| GitHub App          | [ppat-power-platform-git-app](https://github.com/organizations/Powerbouwer/settings/apps/ppat-power-platform-git-app) |
| Client ID           | `Iv23ctl6ddtZt5ovDryP`                                                                                                |

::: warning Keep credentials secure
Never commit the GitHub App Private Key or a Personal Access Token (PAT) to the repository. The team stores a backup of the private key in 1Password.
:::

### 1. Request access

1. Ask a PPAT administrator for the GitHub App private key (`.pem` file).
1. Ask the administrator to grant your account temporary administrator access to the PPAT repository if you don't already have it. You need this access to establish the connection.

### 2. Configure a key vault in Azure

1. In the developer tenant, select an existing Azure Key Vault or create one.
1. Navigate to the **Access control (IAM)** section of the Key Vault.
1. Assign your account the **Key Vault Administrator** role on the vault.
1. In the Key Vault, go to **Keys** and select **Generate/Import**.
1. Select **Import**, choose the supplied `.pem` file, enter a recognizable key name (for example, `ppat-github-app-private-key`), and create the key.
1. Record the Key Vault URI and key name. You need both when connecting the solution.

::: info Import the private key correctly
Import the file as a **key**, not as a secret. See [Configure Azure Key Vault](https://learn.microsoft.com/en-us/power-platform/alm/git-integration/connecting-to-github#configure-azure-key-vault) for the current Microsoft procedure.
:::

### 3. Create a fine-grained personal access token

Create a temporary fine-grained PAT in GitHub for the initial connection:

1. Choose `Powerbouwer` as the resource owner.
1. Limit repository access to the `power-platform-administration-tool` repository.
1. Update the **Contents** permission to **Read and write**.
1. Keep all other repository permissions at their minimum required values.
1. Choose a short expiration period and create the token.
1. Store the token temporarily in a secure location. GitHub only displays it once.

### 4. Connect the solution

1. Navigate to make.preview.powerapps.com
1. Import the unmanaged solution to your environment.
1. On the **Source control** page, select **Connect**, and then select **GitHub**.
1. Enter the GitHub organization `Powerbouwer`, repository `power-platform-administration-tool`, target branch (ask what the current branch is), and Git folder `solutions`.
1. Use the earlier created PAT to authorize the initial connection.
1. Create the GitHub App configuration with the Client ID, Key Vault URI, and imported key name recorded earlier.
1. Complete the connection setup.

::: info Preview feature
The interface is currently a preview feature and can change. Follow [Connect Dataverse Git integration to GitHub](https://learn.microsoft.com/en-us/power-platform/alm/git-integration/connecting-to-github) alongside these project-specific settings.
:::

### 5. Give Dataverse access to the key vault

After you create the GitHub App configuration, Dataverse creates a managed identity for it. Microsoft Entra ID represents this identity as a service principal.

1. Open the Key Vault in the Azure portal and go to **Access control (IAM)**.
1. Add the **Key Vault Crypto User** role assignment.
1. For **Assign access to**, select **User, group, or service principal**. Don't select **Managed identity**, because that list doesn't show the Dataverse identity.
1. Select **Members**, search for the following name, and select the matching application (service principal):

   ```text
   PPMI-githubappconfigmanagedidentity-{GUID}
   ```

::: info Managed identity availability
Dataverse creates the identity asynchronously. If it doesn't appear, check **Settings** > **System Jobs** in the Dataverse environment for GitHub App configuration errors.
:::

### 6. Verify and clean up

1. In the unmanaged solution, open **Source control** > **Git connection**.
1. Verify the provider, organization, repository, branch, and folder.
1. Commit a small solution change to confirm that the end-to-end connection works.
1. Revoke or delete the fine-grained PAT after the test commit succeeds. Runtime access uses the GitHub App.
1. Ask a PPAT administrator to remove temporary repository administrator access after connection setup.

## Branch strategy

Create branches manually from `main` and choose a descriptive name. There's no required branch prefix, solution token, version, or sprint number. Existing branches can keep their names.

1. Create a branch in GitHub or with Git.
1. For solution work, connect each participating developer environment to the agreed branch.
1. Collaborate by pulling from and pushing to that branch.
1. Before merging solution changes to `main`, set each changed solution's version to an unused `X.Y.Z.0` release version.
1. Create or reuse an open `{uniqueName}-vX.Y.Z` milestone for each release. Assign and close the completed issues before merging.
1. Open a pull request to `main` when the work is ready.

Milestone names use `{uniqueName}-vX.Y.Z`. Release tags match the ZIP asset filename prefix: `{uniqueName}_X_Y_Z_0`. For example, `ppat_core` version `1.0.0.0` uses the release tag `ppat_core_1_0_0_0`.

Pull request checks classify changes by file path, not branch name. A PR can change multiple solutions. Spectral checks solution resource naming independently of branch names.

The workflow labels pull requests based on changed paths. It applies `dev` to solution changes, `docs` to documentation changes, and `project` to repository changes. Mixed changes receive multiple labels. Keep development and project changes in separate PRs. Combining them fails validation. You can include documentation changes with either category. Labels show the review scope, and validators enforce the policy.

Developers can share a branch to exchange work between their individual environments through native Git integration. Agree on the branch with the participating developers. Its name doesn't affect validation.

### Patches

Production patches follow a separate path:

1. Create a branch for the fix and increment the build number. For example, a `ppat_core` patch for `ppat_core-v1.0.0` uses solution version `1.0.1.0`.
1. Complete and verify the fix on the patch branch.
1. Merge the patch into `main`.
1. Apply the same patch to any active development branches to carry the fix into the next release.

## Versioning

Power Platform solutions use the following four-part version format:

```text
MAJOR.MINOR.BUILD.REVISION
```

| Part       | Meaning                                                                                            |
| ---------- | -------------------------------------------------------------------------------------------------- |
| `MAJOR`    | Identifies the PPAT module. Each module uses its own major version.                                |
| `MINOR`    | A new feature set or a meaningful increment of work within that module.                            |
| `BUILD`    | The patch number. Increment it for a bug fix or small, nonbreaking change.                         |
| `REVISION` | An automatically incremented deployment iteration within the same major, minor, and build version. |

Each solution has an independent version. Branch names don't determine that version. Before merging solution changes to `main`, update the solution metadata to `X.Y.Z.0` and create or reuse the matching open `{uniqueName}-vX.Y.Z` milestone. The release workflow reads the version from the metadata and rejects an existing release tag.

Store solution metadata in `solutions/{unique name}/solutions/{unique name}/solution.yml`. Release packaging uses `solutions/{unique name}` as the native Dataverse Git YAML root.

### Initialize a new solution

A repository maintainer prepares a solution before its first development cycle:

1. Choose a technical unique name with the `ppat_` prefix and underscores, such as `ppat_change_viewer`.
1. Create a branch from `main`.
1. Connect Power Platform Git integration to the new branch and Git folder `solutions`, then commit the solution. Git integration creates `solutions/{unique name}/`.
1. Assign the new solution an unused `X.Y.Z.0` version and create the matching open release milestone.
1. Open a pull request to `main`. Continue with the normal release process after the solution metadata exists.

The release workflow derives solution names from changed paths and compares them with the solution metadata. It doesn't maintain a separate solution list or derive solution names from branches.

The pull request validation workflow classifies both the old and new paths of a renamed file. For every valid PR, it installs dependencies, audits them, and runs `npm run lint`. That command checks vulnerability documentation, formatting, prose, JavaScript, and solution naming. It doesn't check branch names or compare versions with branch names. If the workflow can't retrieve the diff, it reports an error.

## Documentation changes

Documentation work doesn't require a solution release cycle:

1. Create a branch from `main` in GitHub or with Git.
1. Choose a descriptive name. You don't need a documentation prefix.
1. Commit documentation changes and open a pull request to `main`.

Changes below `docs/`, including `.vitepress/`, are docs work. The PR workflow checks formatting and prose but doesn't build the VitePress site. Changes to `docs/` or either package file trigger the documentation deployment after merge. Documentation changes don't create a solution release.

## Project changes

Repository-wide changes that don't modify Power Platform solutions use a separate branch:

1. Create a branch from `main` in GitHub or with Git.
1. Choose a descriptive name. You don't need a project prefix.
1. Commit the project changes and open a pull request to `main`.

Project changes include repository configuration such as `.github/` and paths outside solution or documentation content. The PR workflow runs the same repository-wide lint checks regardless of the changed category.

You can combine documentation with project or solution changes, but you can't combine solution and project changes in one pull request. Solution changes still require the corresponding solution development and release cycle because merging them to `main` starts the solution release workflow.

## Branch governance

Engineers with repository write access create and update working branches and open pull requests. Branch names don't determine the review scope or required checks.

Repository administrators must also update GitHub settings when removing the branch creation workflows:

1. Open **Settings** > **Rules** > **Rulesets** and inspect the rules that apply to working branches.
1. Remove branch name restrictions and disable **Restrict creations** where it prevents developers from creating working branches. If a ruleset exists only for those restrictions, disable or delete that ruleset.
1. Check **Settings** > **Branches** for classic branch protection rules with equivalent restrictions.
1. Remove required status checks belonging to deleted workflows, if configured. Keep **Validation result**, required reviews, and protections for `main`.

Keep unrelated protections in place. If an organization-level ruleset supplies the restrictions, an organization administrator must update it.

For every pull request targeting `main`, the person who opens it must select a fellow developer as reviewer. A maintainer must approve the pull request before GitHub can merge it.

The **Document issues** workflow still uses the repository secret `BRANCH_AUTOMATION_TOKEN` to create documentation pull requests. Don't delete this secret when removing the branch creation workflows. The team stores the token and its expiration date in a restricted 1Password vault. The repository administrator must renew the token before it expires.

## Release process

Before merging solution changes to `main`, create or reuse an open `{uniqueName}-vX.Y.Z` milestone, assign every completed issue included in the release to it, and close those issues.

Reference related issues in pull requests with `Refs #123`, using one line per issue. A reference makes the relationship visible but doesn't close the issue or include it in release notes. GitHub applies closing keywords such as `Closes #123` only when someone merges a pull request into the default branch. Write release notes manually in GitHub and include the relevant issue links.

When solution files under `solutions/` change on `main`, the release workflow detects all changed solutions and runs these steps for each solution:

1. Reads `X.Y.Z.0` from the solution metadata.
1. Packs managed and unmanaged ZIP files from the repository with Power Platform Actions.
1. Creates a tag matching the ZIP filename prefix, `{uniqueName}_X_Y_Z_0`, and a public GitHub pre-release that isn't marked as **Latest**.
1. Names the solution assets like a platform export: `{unique name}_X_Y_Z_0.zip` for unmanaged and `{unique name}_X_Y_Z_0_managed.zip` for managed.

The builds run in parallel. If one solution fails, the other builds continue. The workflow has no manual trigger and refuses to replace an existing release tag. Before merging to `main`, confirm that each changed solution has a new version.

Manage release scope by assigning issues to milestones in GitHub. The workflow doesn't read or require a milestone and leaves release notes empty for manual editing. Each pre-release contains only the managed and unmanaged ZIP files.

Import the managed ZIP into a test environment and complete acceptance testing. After approval, publish the existing release manually in GitHub:

1. Open [Releases](https://github.com/Powerbouwer/power-platform-administration-tool/releases) and edit the pre-release matching the tag `{uniqueName}_X_Y_Z_0`.
1. Add the release notes and links to the included issues.
1. Remove ` (pre-release)` from the title. Keep the existing tag and ZIP files.
1. Clear **Set as a pre-release** and select **Set as the latest release**.
1. Select **Update release**.
1. Close the matching `{uniqueName}-vX.Y.Z` milestone.

This keeps the tested assets unchanged. Publish releases manually. No separate workflow or automated approval gate handles publication.

## Naming conventions

The team will add naming conventions in a later revision of this guide.
