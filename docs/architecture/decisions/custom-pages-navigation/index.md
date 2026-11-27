---
title: " Custom pages navigation"
issue: 75
issueUrl: "https://github.com/Powerbouwer/power-platform-administration-tool/issues/75"
scope: "Core"
decisionDate: "2026-11-27"
---

#  Custom pages navigation

Source: [Issue #75](https://github.com/Powerbouwer/power-platform-administration-tool/issues/75)

### Scope

Core

### Context and problem statement

Through PPAT, we want to offer users a navigation item for each resource type in a model-driven app. This makes it easy to navigate based on all available resource types.

We also want to use one custom page to provide visibility into all resource types. We do not want to copy custom pages for each resource because of management, changes, and lifecycle management. This custom page contains a View (a grid with the retrieved data/resources) and a Form (a form with details for the selected resource).

Based on the above, we need to find a way to configure navigation (the default in model-driven apps) so that each navigation item in the Inventory group refers to the same custom page, while passing information to the custom page so it can determine which data to retrieve and display.


### Decision drivers

* Use out-of-the-box Power Platform capabilities.
* Configure the custom page once and reuse it based on the selected navigation item

### Considered options

* One custom page per resource type
* JavaScript to manage navigation from the navigation item to the custom page(s)
* One navigation item named Inventory, with filtering by resource type handled within the custom page
* Use the Navigation Link in the model-driven app

### Decision outcome

Navigation Link

We decided to use the Navigation Link option in model-driven apps. This lets us call a relative URL and pass two query parameters to the URL. These query parameters are available by default (as documented by Microsoft) and can be used in the custom page. They are:

* entityName ( &etn={entityname} )
* recordId ( &etn={entityname} )

Normally, `entityName` is used to control navigation based on Dataverse tables. In this case, we can "misuse" this parameter to pass information to the custom page.

The navigation link then looks as follows:

`/main.aspx?pagetype=custom&name=ppat_ppatresources_2c91b&etn=microsoft.powerapps/canvasapps`

In this example, we set the `entityName (etn)` parameter to the resource type value `microsoft.powerapps/canvasapps`. We use this value in the custom page to retrieve the correct resources for this specific resource type.


### Consequences

* We do not use the default functionality for adding a custom page as a navigation item through the UI
* Using a query parameter such as `entityName` could be considered misuse, because we are not directly calling an entity

### Participants

@miguelverweij @arijsdijk 

### Links

<img width="1405" height="618" alt="image" src="https://github.com/user-attachments/assets/3767e32d-f819-4e07-8d66-00800c1c51ad" />
