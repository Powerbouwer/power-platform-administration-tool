---
title: "Developer Guidelines"
layout: doc
---

# Developer Guide

This guide describes how to prepare a development environment and contribute to PPAT through Power Platform native Git integration. Each developer works from a separate developer tenant and environment so that development work remains isolated.

## Prerequisites

Before starting, make sure that you have:

- A developer tenant with a developer environment.
- A managed developer environment. Dataverse Git integration requires a managed environment.
- The System Administrator security role in the Dataverse environment.
- An Azure subscription in the same Microsoft Entra tenant as the Dataverse environment.
- Permission to create an Azure Key Vault and assign roles.

## Set Up Git Integration

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
1. Ask the administrator to grant your account temporary administrator access to the PPAT repository if you do not already have it. This access is required to establish the connection.

### 2. Configure Azure Key Vault

1. In the developer tenant, create or select an Azure Key Vault.
1. Navigate to the **Access control (IAM)** section of the Key Vault.
1. Assign your account the **Key Vault Administrator** role on the vault.
1. In the Key Vault, go to **Keys** and select **Generate/Import**.
1. Select **Import**, choose the supplied `.pem` file, enter a recognizable key name (e.g. `ppat-github-app-private-key`), and create the key.
1. Record the Key Vault URI and key name. You need both when connecting the solution.

::: info Import the private key correctly
Import the file as a **key**, not as a secret. See [Configure Azure Key Vault](https://learn.microsoft.com/en-us/power-platform/alm/git-integration/connecting-to-github#configure-azure-key-vault) for the current Microsoft procedure.
:::

### 3. Create a fine-grained Personal Access Token (PAT)

Create a temporary fine-grained PAT in GitHub for the initial connection:

1. Set the resource owner to `Powerbouwer`.
1. Limit repository access to the `power-platform-administration-tool` repository.
1. Under **Repository permissions**, set **Contents** to **Read and write**.
1. Leave all other repository permissions at their minimum required values.
1. Set a short expiration period and create the token.
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

### 5. Grant Key Vault access to Dataverse

After the GitHub App configuration is created, Dataverse creates a managed identity for it. In Microsoft Entra ID, this identity is represented by a service principal.

1. Open the Key Vault in the Azure portal and go to **Access control (IAM)**.
1. Add the **Key Vault Crypto User** role assignment.
1. For **Assign access to**, select **User, group, or service principal**. Do not select **Managed identity**, because the Dataverse identity does not appear in that list.
1. Select **Members**, search for the following name, and select the matching application (service principal):

	```text
	PPMI-githubappconfigmanagedidentity-{GUID}
	```

::: info Managed identity availability
The identity is created asynchronously. If it is not available yet, wait briefly and check **Settings** > **System Jobs** in the Dataverse environment for errors related to the GitHub App configuration.
:::

### 6. Verify and clean up

1. In the unmanaged solution, open **Source control** > **Git connection**.
1. Verify the provider, organization, repository, branch, and folder.
1. Commit a small solution change to confirm that the end-to-end connection works.
1. Revoke or delete the fine-grained PAT after the test commit succeeds. Runtime access uses the GitHub App.
1. Ask a PPAT administrator to remove any temporary repository administrator access that is no longer required.

## Branch Strategy

PPAT uses shared release and sprint branches:

1. Open **Actions** > **Create development branches** in GitHub.
1. Select the `solution` you are going to work on, enter the three-part release version without a `v` prefix, for example `1.0.0`, and enter the numeric sprint number.
1. The workflow creates `{solution}/v{major}.{minor}.{build}` from `main`, updates that solution to `{major}.{minor}.{build}.0`, and creates the `release:{solution}-v{major}.{minor}.{build}` issue label.
1. The workflow creates `{solution}/spr-{sprint number}` from the release branch. If the release branch already exists with the expected solution version, only the new sprint branch is created.
1. Connect each participating developer environment to the shared sprint branch.
1. Collaborate by pulling from and pushing to that sprint branch.
1. Merge completed sprint work into the release branch. The sprint and release branches must use the same solution namespace.
1. When the release is ready, merge the release branch into `main`.

Branch tokens use kebab-case, while Dataverse solution names use underscores. Workflows add the fixed `ppat_` prefix and replace hyphens with underscores. For example, `core` maps to `ppat_core`, and `change-viewer` maps to `ppat_change_viewer`.

The **Development changes only** check permits a solution pull request to change only its corresponding `solutions/ppat_*/` folder, files below `docs/`, and the root files `package.json`, `package-lock.json`, and `.gitignore`. It checks both current and previous paths for renamed files. A sprint branch may only target its solution's release branch, and a release branch may only target `main`.

Pull requests are automatically labeled by change type. Solution sprint and release pull requests receive `dev`, pull requests from `docs/*` receive `docs`, and pull requests from `project/*` receive `project`. These labels make the expected review scope visible; the branch-route and changed-file checks remain the enforcement mechanism.

We deliberately use a shared sprint branch instead of separate feature branches because development is performed as planned sprint work. Developers regularly need to exchange work between their individual environments, and the shared branch keeps this to a straightforward pull-and-push workflow. It also avoids branch-related issues previously encountered with native Git integration.

### Patches

Production patches follow a separate path:

1. Start a release cycle with an incremented build number. For example, a core patch for `core-v1.0.0` uses version `1.0.1` and branch `core/v1.0.1`.
1. Complete and verify the fix on the patch branch.
1. Merge the patch into `main`.
1. Apply the same patch to the active release branch so that the fix is retained in the next release.


## Versioning

Power Platform solutions use the following four-part version format:

```text
MAJOR.MINOR.BUILD.REVISION
```

| Part       | Meaning                                                                                            |
| ---------- | -------------------------------------------------------------------------------------------------- |
| `MAJOR`    | The PPAT module. Each module is assigned a major version.                                          |
| `MINOR`    | A new feature set or a meaningful increment of work within that module.                            |
| `BUILD`    | The patch number. Increment it for a bug fix or small, nonbreaking change.                         |
| `REVISION` | An automatically incremented deployment iteration within the same major, minor, and build version. |

Release branch names use the first three components of the solution version in `{solution}/vX.Y.Z`. The deployment-generated revision is not included in the branch name. For example, core solution version `1.0.1.4` belongs to release branch `core/v1.0.1`. Solutions are versioned independently.

Solution metadata is stored in `solutions/{unique name}/solutions/{unique name}/solution.yml`. Release packaging uses `solutions/{unique name}` as the native Dataverse Git YAML root.

### Initialize a new solution

A repository maintainer prepares a solution before its first development cycle:

1. Add its kebab-case token to the solution dropdown in the **Create development branches** workflow. This dropdown is the only registered-solution list. The technical unique name is `ppat_` plus the token with hyphens replaced by underscores.
1. Run **Create development branches**. The workflow may create the release and sprint branches even though the solution folder doesn't exist yet.
1. Connect Power Platform Git integration to the new sprint branch and Git folder `solutions`, then commit the solution. Git integration creates `solutions/{unique name}/`.
1. Set the new solution's version to the `X.Y.Z.0` version represented by the target release branch. The **Development changes only** check enforces this version before merge.
1. Open a pull request from the sprint branch to its release branch. Continue with the normal release process after the solution metadata exists.

The scope, release, and publishing workflows derive solution names from branches, changed paths, or tags. They validate the derived technical name against the solution metadata, so they don't maintain separate solution lists.

Existing branches and tags that predate the solution namespaces are not renamed. New development cycles use only the namespaced format.

## Documentation Changes

Documentation work does not require a solution release cycle:

1. Open **Actions** > **Create documentation branch**.
1. Enter a short lowercase kebab-case name, for example `update-installation`.
1. The workflow creates `docs/update-installation` from the current `main` branch.
1. Commit documentation changes and open a pull request to `main`.

A pull request from `docs/*` may modify files below `docs/`, plus the root files `package.json`, `package-lock.json`, and `.gitignore`. The package files are included because they configure and lock the VitePress toolchain. The **Documentation changes only** check blocks all other renamed, removed, or added files. Changes to `docs/` or either package file trigger the documentation deployment after merge. Documentation changes don't create a solution release.

## Project Changes

Repository-wide changes that don't modify Power Platform solutions use a separate project branch:

1. Open **Actions** > **Create project branch**.
1. Enter a short lowercase kebab-case name, for example `update-workflows`.
1. The workflow creates `project/update-workflows` from the current `main` branch.
1. Commit the project changes and open a pull request to `main`.

The **Project files only** check allows changes anywhere in the repository except below `solutions/`. This includes repository configuration, workflows, community files, build and CI/CD tooling, package files, and documentation. Changes below `solutions/` require the corresponding solution development and release cycle, because merging them to `main` starts the solution release workflow.

The check evaluates both the current and previous paths of renamed files. Moving a file into or out of `solutions/` is therefore also blocked on a project branch.

## Branch Governance

Engineers with repository write access can update existing sprint, documentation, and project branches and open pull requests. They don't create branches manually. Maintainers have ruleset bypass access for exceptional recovery work, so this policy deliberately has a controlled administrative escape hatch.

Configure the following repository settings under **Settings** > **Rules** > **Rulesets**:

1. Create an active branch ruleset targeting all branches.
1. Enable **Restrict creations**, **Restrict deletions**, and **Block force pushes**.
1. Add a branch-name restriction that must match this regular expression:

	```text
	^(main|v[0-9]+\.[0-9]+\.[0-9]+|spr-[0-9]+|[a-z0-9]+(-[a-z0-9]+)*\/(v[0-9]+\.[0-9]+\.[0-9]+|spr-[0-9]+)|docs\/[a-z0-9]+(-[a-z0-9]+)*|project\/[a-z0-9]+(-[a-z0-9]+)*)$
	```

	The solution namespace accepts lowercase kebab-case tokens. Branch creation remains restricted by the workflow dropdown and repository permissions. The legacy `vX.Y.Z` and `spr-N` alternatives keep existing development cycles operable; the branch workflow no longer creates branches in those formats.

1. Add the maintainer team to the bypass list with **Always allow**. Organization owners can also be added as an explicit break-glass bypass.
1. Create additional rulesets for `main` and the solution release branches that require pull requests and block deletion and force pushes.
1. Require the **Documentation changes only**, **Project files only**, and **Development changes only** status checks on pull requests to `main`. Require **Development changes only** on pull requests to solution release branches as well. Each check is skipped successfully when its corresponding branch type isn't used.
1. Test new rulesets in **Evaluate** mode before changing them to **Active**.

The branch workflows must authenticate as a bypass actor because the built-in Actions token doesn't inherit the permissions of the maintainer who starts a workflow. Create a fine-grained token owned by a maintainer or dedicated automation account in the bypass team and grant it **Contents: read and write** and **Issues: read and write** for this repository. Store the token and its expiration date in the team's restricted 1Password vault, and configure the same token value in GitHub as the repository secret `BRANCH_AUTOMATION_TOKEN`. Expiration notifications are managed from the 1Password record. The repository administrator is responsible for renewing the token before it expires.

Renew the automation token shortly before it expires:

1. Regenerate the existing fine-grained token in GitHub and select a new expiration date. Regeneration immediately invalidates the previous token value, so complete the remaining steps without delay.
1. Replace the credential and expiration date in the existing 1Password item.
1. Update the existing GitHub repository secret `BRANCH_AUTOMATION_TOKEN` with the regenerated token value.
1. Verify the regenerated token by running one of the branch-creation workflows.

## Release Process

Before merging a release branch to `main`, add `release:{solution}-vX.Y.Z` to every issue included in the release and close the completed issues.

When solution files under `solutions/` change on `main`, the release workflow:

1. Confirms that exactly one registered solution changed and reads `X.Y.Z.0` from its metadata.
1. Packs managed and unmanaged ZIP files from the repository with Power Platform CLI.
1. Validates both packages and generates SHA-256 checksums.
1. Creates tag `{solution}-vX.Y.Z` and a public GitHub pre-release that isn't marked as **Latest**.
1. Names the solution assets `{unique name}_vX.Y.Z_managed.zip` and `{unique name}_vX.Y.Z_unmanaged.zip`.
1. Adds all closed issues with label `release:{solution}-vX.Y.Z` to the release notes.

Import the managed ZIP into a test environment and complete acceptance testing. When approved, open **Actions** > **Publish solution release**, enter the existing `{solution}-vX.Y.Z` tag, and approve the `production-release` environment when required. Publishing removes the pre-release status and marks the same release as stable and **Latest**. It doesn't change visibility, rebuild, or replace its assets.

Configure the `production-release` GitHub Environment with required reviewers to separate testing from production approval.

## Naming Conventions

Naming conventions will be added in a later revision of this guide.