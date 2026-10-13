---
title: "Architecture"
layout: doc
---

<script setup>
import { data as decisions } from './decisions/decisions.data.mjs'
</script>

# Architecture

This section describes the architecture of the Power Platform Administration Tool.

## Overview

The system context, major components, and their responsibilities are not yet documented.

## Architecture decisions

Architecture decisions are tracked as GitHub issues of type `ADR`.

When an ADR issue is closed as completed, a documentation pull request is generated. Issues closed as not planned are not documented.

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

Dependencies and integration points, including use of the Power Platform Inventory API, will be documented here.

## Security

Identity, permissions, data handling, and security boundaries will be documented here.