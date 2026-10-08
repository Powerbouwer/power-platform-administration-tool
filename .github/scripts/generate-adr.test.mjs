import assert from 'node:assert/strict'
import { mkdtemp, mkdir, readFile, writeFile } from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import test from 'node:test'

import {
  createAdr,
  generateFromEvent,
  parseIssueForm,
  validateAdrEvent,
  validateAdrIssue
} from './generate-adr.mjs'

const body = `### Scope

Core

### Context and problem statement

We need a consistent data store.

### Decision drivers

- Relational data
- Governed access

### Considered options

- SharePoint: simple, but limited relationships.
- Dataverse: governed and relational.

### Decision outcome

Use Dataverse because it supports the required security and relationships.

### Consequences

Environments require Dataverse capacity.

### Participants

@engineer-one, @engineer-two

### Links

#42`

function issue(overrides = {}) {
  return {
    number: 123,
    title: '🧭 [ADR] Use Dataverse for configuration data',
    body,
    type: { name: 'ADR' },
    created_at: '2026-09-28T10:00:00Z',
    closed_at: '2026-10-06T14:30:00Z',
    state_reason: 'completed',
    ...overrides
  }
}

async function workspace() {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ppat-adr-'))
  const architecture = path.join(root, 'docs', 'architecture')
  await mkdir(architecture, { recursive: true })
  await writeFile(
    path.join(architecture, 'index.md'),
    '# Architecture\n\n<!-- ADR-LIST:START -->\n<!-- ADR-LIST:END -->\n'
  )
  return root
}

test('parses multiline issue form fields', () => {
  const fields = parseIssueForm(body)
  assert.match(fields['Considered options'], /SharePoint[\s\S]*Dataverse/)
  assert.equal(fields.Participants, '@engineer-one, @engineer-two')
})

test('creates a solution ADR directly from issue fields', () => {
  const adr = createAdr(issue())
  assert.equal(adr.fileName, 'issue-123-use-dataverse-for-configuration-data.md')
  assert.match(adr.content, /scope: solution\nsolution: ppat_core/)
  assert.match(adr.content, /proposedDate: 2026-09-28/)
  assert.match(adr.content, /decisionDate: 2026-10-06/)
  assert.match(adr.content, /## Participants\n\n@engineer-one, @engineer-two/)
})

test('creates a repository-wide ADR with a safely quoted title', () => {
  const adr = createAdr(issue({
    title: '🧭 [ADR] Prefer "configuration as code": repository-wide',
    body: body.replace('Core', 'Repository-wide')
  }))

  assert.match(adr.content, /title: "Prefer \\"configuration as code\\": repository-wide"/)
  assert.match(adr.content, /scope: repository/)
  assert.doesNotMatch(adr.content, /solution:/)
})

test('generates one idempotent ADR and index entry', async () => {
  const root = await workspace()
  const event = { action: 'closed', issue: issue() }

  await generateFromEvent(event, root)
  await generateFromEvent(event, root)

  const generated = await readFile(
    path.join(root, 'docs', 'architecture', 'decisions', 'issue-123-use-dataverse-for-configuration-data.md'),
    'utf8'
  )
  const index = await readFile(path.join(root, 'docs', 'architecture', 'index.md'), 'utf8')

  assert.match(generated, /## Decision outcome\n\nUse Dataverse because/)
  assert.equal((index.match(/\| 123 \|/g) ?? []).length, 1)
})

test('skips not-planned and non-ADR closures', async () => {
  const root = await workspace()
  assert.equal(
    await generateFromEvent({ action: 'closed', issue: issue({ state_reason: 'not_planned' }) }, root),
    null
  )
  assert.equal(
    await generateFromEvent({ action: 'closed', issue: issue({ type: { name: 'Task' } }) }, root),
    null
  )
})

test('validates the complete closed issue before generation', () => {
  assert.doesNotThrow(() => validateAdrEvent({ action: 'closed', issue: issue() }))
  assert.throws(
    () => validateAdrEvent({ action: 'closed', issue: issue({ body: body.replace('### Decision drivers', '### Drivers') }) }),
    /Missing required ADR fields: Decision drivers/
  )
})

test('validates an open ADR issue without a decision date', () => {
  assert.doesNotThrow(() => validateAdrIssue(issue({ closed_at: null, state_reason: null })))
  assert.throws(
    () => validateAdrIssue(issue({ body: body.replace('Core', 'Unknown solution') })),
    /Unsupported ADR scope: Unknown solution/
  )
})

test('rejects missing required fields', () => {
  assert.throws(
    () => createAdr(issue({ body: body.replace('Use Dataverse because it supports the required security and relationships.', '_No response_') })),
    /Missing required ADR fields: Decision outcome/
  )
})