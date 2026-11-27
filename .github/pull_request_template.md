## Scope

Select the applicable scope section(s) below and remove the unused sections before submitting.

- [ ] Solution Development
- [ ] Bug fix
- [ ] Documentation
- [ ] Architecture decision record (ADR)
- [ ] GHSA / Vulnerability
- [ ] Project work

## Summary

<!-- Describe what changed and why. -->

## Verification

<!--
Describe the test or review steps and their results. If not tested, explain why.
Confirm that all completed issues in the milestone are closed before merging into `main`.
-->

## Solution Development

- [ ] The change delivers the desired outcome and meets the issue's acceptance criteria.
- [ ] Keep the change within the agreed scope. Don't include unrelated work.
- [ ] Limit solution changes to one solution. Track related work in other solutions in separate, linked PRs.
- [ ] If this PR changes a solution and targets `main`, confirm that its version is higher than the version on `main`.
- [ ] Follow the issue's technical constraints and applicable repository standards.
- [ ] `npm run lint` passes.
- [ ] Appropriate tests or manual verification confirm the delivered behavior, and applicable checks pass.
- [ ] Update user-facing documentation or release notes for this behavior where needed.
- [ ] Don't add credentials or other sensitive data to files, test logs, screenshots, or other artifacts.

## Bug fix review

- [ ] The change addresses the observed and expected behavior described in the bug issue. Check the fix with the issue's reproduction steps.
- [ ] Limit the fix to the reported problem and affected solutions. Don't include unrelated changes.
- [ ] If this PR changes a solution and targets `main`, confirm that its version is higher than the version on `main`.
- [ ] A regression test or appropriate manual regression check covers the reported behavior.
- [ ] Relevant tests pass.
- [ ] Test logs, screenshots, and other artifacts contain no credentials or other sensitive data.

## Documentation review

- [ ] Keep all changed files under `docs/`. Don't change solutions or project/repository structure.
- [ ] Review the documentation for accuracy, clarity, and relevance. Critically review and edit AI-generated or AI-assisted text.
- [ ] Follow the repository's Markdown and documentation standards.
- [ ] `npm run lint` passes.
- [ ] `npm run docs:build` passes, and the page is in the correct location and navigation.
- [ ] Check internal links, examples, commands, and referenced sources where applicable.

## Review generated ADR

This pull request publishes the architecture decision agreed in the linked ADR issue.

- [ ] The only change is the new ADR Markdown page under `docs/architecture/decisions/`.
- [ ] The page accurately reflects the final decision and discussion recorded in the issue.
- [ ] The title, scope, issue reference, and decision date are correct.
- [ ] The page includes the agreed consequences and any follow-up actions.
- [ ] There are no placeholders or unrelated changes.

## GHSA / Vulnerability review

This pull request implements or documents the decision for the vulnerability described in the linked issue.

- [ ] The linked issue identifies the GHSA, severity, affected package, installed version, dependency type, usage, and dependency path.
- [ ] The impact assessment includes evidence about whether users use the vulnerable functionality and which mitigations apply.
- [ ] The changes match the proposed decision recorded in the issue.
- [ ] A temporary exception includes a proposed expiry date.
- [ ] Dependency and lockfile changes are consistent with the decision.
- [ ] The Audit CI check (`npm run audit`) passes.
- [ ] Relevant checks have passed.
- [ ] There are no unrelated changes.

## Project work review

- [ ] The change addresses the issue's desired outcome and respects its constraints.
- [ ] Keep the change to the intended repository, automation, tooling, or process work. Don't include solution changes or unrelated work.
- [ ] Run all available local checks and confirm they pass.
- [ ] Confirm that applicable GitHub Actions checks for this PR pass.
- [ ] Review changed workflows for configuration, triggers, and permissions.
- [ ] If you couldn't test behavior before merge, record it in the issue and explain how you'll verify it afterward.
- [ ] Assess the impact on existing automation, tooling, dependencies, and release processes where applicable.
- [ ] Update any required maintainer or contributor guidance.
- [ ] Don't add credentials or other sensitive data to files, logs, or other artifacts.
