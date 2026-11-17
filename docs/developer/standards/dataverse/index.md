---
title: Dataverse standards
---

# Dataverse

Follow the [shared low-code-first and configuration guidance](../). Keep technical schema names distinct from readable display labels.

## Naming rules

<a id="dv-001"></a>

### Dataverse table technical names

**Manual review required (not automated yet):** `Entity.Name` starts with a letter and contains only letters, digits, and underscores. Good: `ppat_environment`. Bad: `Environment Table`.

<a id="ppat-003"></a>

### Dataverse publisher-prefix convention

**Manual review required (not automated yet):** Names with an underscore must use the solution publisher's `CustomizationPrefix` followed by `_`. For prefix `ppat`, use `ppat_environment`, not `new_environment`. Treat plain names without an underscore, such as `account`, as platform table names. This rule doesn't assign them a custom prefix. It uses a naming heuristic, not metadata-based ownership detection. Review an explicit rule adjustment for external custom tables. Don't rename someone else's schema.

**Coverage:** Spectral can check both rules once the repository contains a real table export. The current solution contains no table. The team hasn't verified the file path or structure of `entity.yml`, so `.spectral.yaml` doesn't include these rules. The check doesn't cover column, relationship, key, or choice internals.

Don't change an established logical or schema name just to resolve a lint issue. Resolve the original authoring or publisher choice, or review an external-component exception.

## Naming guidance (manual review required)

- Table labels use meaningful singular and plural names, such as `Environment` and `Environments`.
- Display labels use readable words. Technical schema names carry the publisher prefix. Logical names are lowercase, unlike `SchemaName` values.
- Lookup labels describe the target, such as `Environment`. Technical lookup names can end in `id`. A lookup and its relationship form a connected pair.
- Use a consistent relationship naming convention, such as `ppat_resource_N1_environment` or `ppat_resource_NN_tag`. N:1 and 1:N are perspectives on one relationship.
- Business rule: `Table - Purpose - Target`, for example `Environment - Validation - Retention Date`.
- Security role/profile: `PPAT Module - Role`, for example `PPAT Core - Reader`.
- Environment variable/connection reference: `PPAT Module - Purpose`, with useful descriptions.

## Data and security review (manual review required)

- Use system GUID primary keys. Choose alternate keys for real uniqueness or integration needs. Composite keys can be valid. An async flow can't enforce an invariant within a completed transaction.
- Use global choices for shared semantics and local choices for genuinely local behavior. Don't renumber existing option values for cosmetic reasons.
- Use colors with sufficient contrast and understandable labels. Pastel is a style choice, not proof of contrast.
- Review ownership, cascade behavior, required fields, normalization and the effect of changes on existing data.
- Apply least privilege and field security where appropriate. Exported role metadata doesn't prove actual assignments or runtime access.
- Choose declarative business rules, formula/rollup columns, and flows according to their supported scope and timing. Don't call all classic workflows obsolete or always favor low-code plugins.
- Treat indexing as a platform performance concern, not as an instruction for makers to create SQL indexes. Dataverse Search configuration isn't relational query-index configuration.
- Environment-independent defaults can be useful. Exclude development current values from distributed solutions. Use supported secret handling instead of plaintext credentials.
- Document dependencies, installation, monitoring and limitations in the appropriate solution documentation.

Plugins and custom workflow activities are exceptions requiring an approved ADR, not standard PPAT building blocks. DLP, licenses, tenant identities, secret rotation and deployment verification remain separate administration tasks.
