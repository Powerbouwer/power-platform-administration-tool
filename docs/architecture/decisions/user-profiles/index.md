---
title: "User profiles"
issue: 35
issueUrl: "https://github.com/Powerbouwer/power-platform-administration-tool/issues/35"
scope: "Core"
decisionDate: "2026-11-27"
---

# User profiles

Source: [Issue #35](https://github.com/Powerbouwer/power-platform-administration-tool/issues/35)

### Scope

Core

### Context and problem statement

Inventory retrieves and displays large datasets that often contain references to users. These datasets provide only the users' GUIDs. To make the data understandable and support meaningful filtering, these GUIDs need to be mapped to user information, such as display names, so that users do not have to work with IDs alone.

The Inventory API does not provide built-in user resources, components, or options that would allow the query to join user details directly to the inventory data. This mapping therefore needs to be handled elsewhere, either in Search Inventory or in the custom pages.

User information is needed in several places in the custom pages:

- **View:** Show the user's display name alongside their ID in inventory views.
- **Filter:** Allow users to filter by fields such as Created By, using a display name rather than an ID.
- **Form:** Show the user's display name alongside their ID on forms.
- **User details:** Consider adding a user details side pane to forms to show additional information, such as contact details, department, and manager.


### Decision drivers

- Use out-of-the-box Power Platform capabilities.
- Support users across the tenant, not only users in a single environment.
- Account for performance when working with large datasets.

### Considered options

- Connectors such as Office 365 Users or Microsoft Entra ID can retrieve user information, but using them to enrich large datasets may add significant overhead and affect performance.
- The Dataverse `systemuser` table is environment-specific and does not contain the complete tenant-wide user list required here.


### Decision outcome

For now, use two approaches:

- The AAD Users virtual table in Dataverse.
- A connector.

For enriching large datasets used by views and forms, use the AAD Users virtual table in Dataverse. Do not look up users separately for every resource. First create a distinct list of user IDs, then retrieve details for those users. Limit the retrieved information to what is needed, such as the user's display name.

If a user details (Screen Form) is implemented, use a connector to retrieve the additional user information it requires.

For multiple users in one view we will use the virtual table approach. For one user, where we need more detailed information we will use the connector. 

For none existing users we will use the label "Unknown user".

### Consequences

**Positive**

- User display names can be shown alongside user IDs in inventory views and forms.
- A distinct list of user IDs avoids repeating the same user lookup for every resource.
- A consistent approach to retrieving and presenting user information can be used across the solution.
- The AAD Users virtual table provides access to tenant-wide user information without relying on an environment-specific user list.


**Negative or trade-offs**

- Enriching inventory data with user details adds processing and data retrieval, which may affect performance. The impact needs to be measured with representative dataset sizes.
- Additional logic is required in the Search Inventory flow or custom pages to map user IDs to user details.
- The implementation location for enriching view and form data has not yet been decided, so this ADR does not define where that mapping logic will live.
- A user details Screen Form requires a separate connector integration and may introduce additional latency and connection or permission requirements.

### Participants

@arijsdijk @miguelverweij 

### Links

_No response_
