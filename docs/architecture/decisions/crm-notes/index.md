---
title: " CRM Notes"
issue: 76
issueUrl: "https://github.com/Powerbouwer/power-platform-administration-tool/issues/76"
scope: "Core"
decisionDate: "2026-11-27"
---

#  CRM Notes

Source: [Issue #76](https://github.com/Powerbouwer/power-platform-administration-tool/issues/76)

### Scope

Core

### Context and problem statement

Within PPAT, there is a need for a CRM for Inventory as well as additional items. We want to be able to link notes to all inventory resources, as well as to workloads, Message Center messages, and groups of users, such as resolution groups. These notes must then be visible to everyone involved.


### Decision drivers

* Use out-of-the-box Power Platform capabilities.
* Accessible functionality, with a simple way to add a note with additional settings
* Possibility to send notes as notifications from the same source


### Considered options

* Use the notes option for each Dataverse entity (however, resource types are not entities but come from an API)
* Use one table with metadata and enable Notes on it (complex to reuse that data consistently throughout the app)


### Decision outcome

Dataverse entity: CRM Notes

We have decided to use a custom entity in Dataverse for notes. Each note will have its own record in this entity, linked to an object (resource, workload, etc.).


| Column | Type | Mandatory | Description |
| --- | --- | --- | --- | 
| Item Type | Text (single line) | Yes | The object for which you want to create a note, such as a workload, Message Center, or resource type |
| Item ID | Text (Key) | No | The GUID of the resource related to `Item Type` (for example, for the `Cloud flow` object, the resource GUID of this flow) |
| Parent ID | Text | No | When an environment is involved, always enter the Environment GUID of the associated environment |
| Note | Text (multi line) | Yes | The note about the object |
| Is Notification | Boolean (default: no) | Yes | Determines whether a notification should also be displayed and sent within PPAT |
| Notification Severity | Text (single line) | No | Determines the notification type (Error, Warning, Information, or Success) |
| Notification Read | Boolean (default: No) | Yes | Determines whether the in-app notification has been read. This requires an action by the user/user group. |
| Admin Only | Boolean (default: Yes) | Yes | Determines whether the note is intended only for Administrators and is therefore not visible to others |


**Naming**

The column names `Item Type` and `Item ID` were chosen deliberately to keep them generic. An object can be an inventory resource, as well as a workload or resolution group, which falls outside the category of inventory resources.

**Notifications**

Because we want to handle notes and notifications in one solution, several settings specifically for notifications have been added.

*Is Notification* 
Determines whether the note should also be treated as a notification, in-app and possibly also as a Teams or email message.

*Notification Severity* 
Determines the notification type, so that a notification can optionally be given a higher priority.

*Notification Read* 
Determines whether the notification has been read by the user/user group. This is a user action. Each in-app notification gets a "Read" button. Selecting it changes this status to Yes and hides the in-app notification. Because all notifications are also automatically notes, they are "never" lost and remain visible in the notification pane within the model-driven app screens.

**Admin Only** 
With this setting, an Administrator can create notes that can only be viewed by other Administrators. These notes are not visible to other users. As an Administrator, you always have the freedom to publish them (that is, make them visible) to everyone involved.


### Consequences

* Custom entity in the solution
* Lifecycle for Notes when, for example, resources are deleted

### Participants

@miguelverweij @arijsdijk 

### Links

_No response_
