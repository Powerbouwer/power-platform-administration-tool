---
title: "Development server vulnerability in esbuild"
ghsa: "GHSA-67mh-4wv8-2f99"
issue: 73
issueUrl: "https://github.com/Powerbouwer/power-platform-administration-tool/issues/73"
severity: "Moderate"
affectedPackage: "esbuild"
installedVersion: "0.21.5"
dependencyType: "Transitive"
usage: "Development"
proposedDecision: "Accept the risk"
proposedExpiry: ""
decisionDate: "2026-11-13"
---

# Development server vulnerability in esbuild

Source: [Issue #73](https://github.com/Powerbouwer/power-platform-administration-tool/issues/73)

### Advisory identifier

GHSA-67mh-4wv8-2f99

### Severity

Moderate

### Affected package

esbuild

### Installed version

0.21.5

### Dependency type

Transitive

### Usage

Development

### Dependency path

`vitepress > vite > esbuild`

### Vulnerable functionality

`esbuild.serve()`

### Vulnerable functionality in use

No

### Evidence

The [GitHub advisory](https://github.com/advisories/GHSA-67mh-4wv8-2f99) reports that the esbuild development server can let websites read its responses. It affects esbuild versions up to and including 0.24.2. The first patched version is 0.25.0. GitHub rates the severity as moderate, with a Common Vulnerability Scoring System (CVSS) score of 5.3.

`npm explain esbuild` identifies esbuild 0.21.5 as a development dependency introduced through VitePress 1.6.4 and Vite 5.4.21. The documentation development command runs `vitepress dev docs`. Inspection of the installed VitePress code shows that it starts the Vite development server. Vite creates its own HTTP server and imports the esbuild build and transform functions. The repository configuration and scripts don't directly invoke the esbuild serve functionality.

This assessment covers the inspected repository configuration and installed dependency versions. It doesn't establish that other uses of the esbuild server are safe.

### Proposed decision

Accept the risk

### Proposed expiry

_No response_
