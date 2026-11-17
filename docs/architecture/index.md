---
title: "Architecture"
layout: doc
---

<script setup>
import { data as decisions } from './decisions/decisions.data.mjs'
import { data as vulnerabilities } from './vulnerabilities/vulnerabilities.data.mjs'
</script>

### Architecture

This section describes the architecture of the Power Platform Administration Tool.

## Overview

The system context, major components, and their responsibilities aren't yet documented.

## Architecture decisions

You can register Powerbouwer an ADR as GitHub issues of type `ADR`.

Closing an ADR issue as completed generates a documentation pull request. The workflow doesn't document ADR issues closed as not planned.

See the architecture decisions below.

<table>
  <thead>
    <tr><th>Decision</th><th>Scope</th><th>Decision date</th><th>Issue</th></tr>
  </thead>
  <tbody>
    <tr v-for="d in decisions" :key="d.issue">
      <td><a :href="d.url">{{ d.title }}</a></td>
      <td>{{ d.scope }}</td>
      <td>{{ new Date(d.decisionDate).toISOString().slice(0, 10) }}</td>
      <td><a :href="d.issueUrl">#{{ d.issue }}</a></td>
    </tr>
  </tbody>
</table>

## Integrations

This section will describe dependencies and integration points, including use of the Power Platform Inventory API.

## Security

This section will describe identity, permissions, data handling, and security boundaries.

### Vulnerabilities

Track vulnerabilities in GitHub issues of type `vulnerability`.

When someone closes a vulnerability issue as completed, the workflow generates a documentation pull request. The workflow doesn't document issues closed as not planned. Each GHSA has one page. Later registrations for the same GHSA update that page.

The documentation records the proposed decision for review. Documentation doesn't automatically approve a risk or change the audit allowlist.

Every entry in the `audit-ci.json` allowlist requires a file at `docs/architecture/vulnerabilities/<GHSA>/index.md`. Use the complete GHSA as the folder name. The data loader accepts either a GHSA string or an object keyed by a GHSA, including inactive entries.

Run `npm run check:vulnerabilities` from the repository root, locally, or in CI. The command needs no dependency installation and exits with code `1` when documentation is missing or an entry doesn't identify one GHSA. It checks that the file exists, not its contents.

<p v-if="vulnerabilities.length === 0">No vulnerabilities appear in the documentation.</p>

<table v-else>
  <thead>
    <tr><th>GHSA</th><th>Severity</th><th>Package</th><th>Proposed decision</th><th>Proposed expiry</th><th>Decision date</th><th>Issue</th></tr>
  </thead>
  <tbody>
    <tr v-for="v in vulnerabilities" :key="v.ghsa">
      <td><a :href="v.url">{{ v.ghsa }}</a></td>
      <td>{{ v.severity }}</td>
      <td>{{ v.affectedPackage }}</td>
      <td>{{ v.proposedDecision || '-' }}</td>
      <td>{{ v.proposedExpiry || '-' }}</td>
      <td>{{ v.decisionDate }}</td>
      <td><a :href="v.issueUrl">#{{ v.issue }}</a></td>
    </tr>
  </tbody>
</table>
