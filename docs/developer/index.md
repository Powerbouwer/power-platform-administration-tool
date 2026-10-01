---
title: "Developer Guidelines"
layout: doc
---

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

PPAT uses shared version and sprint branches:

1. Create the version branch for the next release from `main`. Use the format `v{major}.{minor}.{build}`, for example `v1.0.0`.
1. Create a sprint branch from the active version branch using the format `spr-{sprint number}`, for example `spr-12`.
1. Connect each participating developer environment to the shared sprint branch.
1. Collaborate by pulling from and pushing to that sprint branch.
1. Merge completed sprint work into the version branch.
1. When the release is ready, merge the version branch into `main`.

We deliberately use a shared sprint branch instead of separate feature branches because development is performed as planned sprint work. Developers regularly need to exchange work between their individual environments, and the shared branch keeps this to a straightforward pull-and-push workflow. It also avoids branch-related issues previously encountered with native Git integration.

### Patches

Production patches follow a separate path:

1. Create a patch branch from `main` by incrementing the build number of the released version. For example, a patch for `v1.0.0` uses the branch name `v1.0.1`.
1. Complete and verify the fix on the patch branch.
1. Merge the patch into `main`.
1. Apply the same patch to the active version branch so that the fix is retained in the next release.


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

Version branch names use the first three components of the solution version, prefixed with `v`. The deployment-generated revision is not included in the branch name. For example, solution version `1.0.1.4` belongs to branch `v1.0.1`.

## Naming Conventions

Naming conventions will be added in a later revision of this guide.