# Dataverse

Model business meaning first using supported tables, relationships, choices, keys and ownership. Use the shared [naming conventions](./naming#dataverse-names). Static Dataverse naming/description checks are **planned**, not implemented: representative native table/column exports must be verified first.

## Tables and columns

**DATAVERSE-METADATA (must, manual / planned automation):** give custom tables and columns meaningful display names and descriptions. Explain units, permitted values and business meaning, not just repeat the name. Distinguish display names, schema names and logical names, and use the real publisher prefix exactly once.

Do not rename system components or technical identities by editing filenames. Schema/logical-name changes can require migration and dependency work.

Choose types and precision based on the data and expected queries. Use Business Required where appropriate, but do not assume it is a database constraint enforced identically for all API clients. Establish critical server-side invariants through a supported mechanism that actually enforces them.

## Relationships and choices

**DATAVERSE-RELATIONSHIP (should, manual):** describe cardinality and ownership clearly. 1:N and N:1 describe the same relationship from opposite directions. A lookup column and the relationship schema are related but distinct identities. Review cascading behavior and test deletion/assignment consequences.

Use global choices when the values have shared semantics; local choices can be correct for table-specific meaning. Keep stable numeric choice values once used. Do not renumber values for cosmetic consistency. Color is supplementary: labels and accessible contrast must communicate the meaning too.

## Keys and integrity

**DATAVERSE-KEY (must, manual):** design alternate keys around real uniqueness. A composite key is valid when uniqueness depends on multiple columns. Consider nulls, key activation and integration behavior.

An asynchronous flow checking after a save does not guarantee uniqueness or immutability at the transaction boundary. Prefer native constraints where they satisfy the requirement; choose an appropriate supported server-side mechanism for other critical invariants.

## Ownership and permissions

**DATAVERSE-ACCESS (must, manual/environment test):** use least privilege and test the effective access of representative non-admin users. Roles accumulate, and user/team ownership, privilege depth, sharing and record access affect the outcome. A single exported security role cannot prove every user's effective rights.

### Append and Append To

| Privilege | Meaning |
| --- | --- |
| Append | This record can be associated with another record. |
| Append To | Other records can be associated with this record. |

For a **Certificate** lookup to **Qualification**, the Certificate needs **Append** and the Qualification needs **Append To**, at sufficient access depth for the records involved. Depending on the operation, Create/Read/Write and related-record access are also needed.

Test creating a Certificate with the lookup, changing the lookup, and denied access when either privilege or record access is missing. "Child" and "parent" are useful shorthand for this lookup example, not a universal explanation of every association, particularly N:N relationships.

Hiding a field or command in an app does not revoke Dataverse permissions.

## Queries and maintenance

**DATAVERSE-QUERY (should, manual):** filter at the source, select necessary columns, use supported paging and measure real workloads. Use supported diagnostics and alternate keys when appropriate. Dataverse Search configuration is not an interface for managing custom SQL indexes.

Review retention, cascading and ownership with the people responsible for the data. Prefer supported standard/low-code features; the low-code preference is not permission to use unsuitable or unapproved preview functionality.

## Sources

- [Column metadata and required levels](https://learn.microsoft.com/power-apps/developer/data-platform/entity-attribute-metadata)
- [Roles, privilege depth and Append/Append To](https://learn.microsoft.com/power-platform/admin/security-roles-privileges)
- [Query anti-patterns](https://learn.microsoft.com/power-apps/developer/data-platform/query-antipatterns)
