import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { existsSync } from 'node:fs'
import { chmod, mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'

const workflows = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'workflows')

const bash = process.platform === 'win32' && existsSync('C:\\Program Files\\Git\\bin\\bash.exe')
  ? 'C:\\Program Files\\Git\\bin\\bash.exe'
  : 'bash'

const hasRuby = spawnSync(bash, ['--noprofile', '--norc', '-c', 'command -v ruby']).status === 0

async function stepScript(workflow, stepName) {
  const lines = (await readFile(path.join(workflows, workflow), 'utf8')).split(/\r?\n/)
  const step = lines.findIndex((line) => line.trim() === `- name: ${stepName}`)
  assert.notEqual(step, -1, `Step ${stepName} not found in ${workflow}`)
  const run = lines.findIndex((line, index) => index > step && line.trim() === 'run: |')
  const indent = lines[run + 1].match(/^ */)[0].length
  const script = []
  for (const line of lines.slice(run + 1)) {
    if (line.trim() !== '' && line.match(/^ */)[0].length < indent) break
    script.push(line.slice(indent))
  }
  return script.join('\n')
}

async function runStep(workflow, stepName, { paths = [], ghExit = 0, env = {}, setup } = {}) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'ppat-scope-'))
  const bin = path.join(root, 'bin')
  await mkdir(bin)
  await writeFile(path.join(root, 'gh-output.txt'), paths.map((entry) => `${entry}\n`).join(''))
  await writeFile(
    path.join(bin, 'gh'),
    '#!/usr/bin/env bash\ncat "$FAKE_GH_OUTPUT"\nexit "$FAKE_GH_EXIT"\n'
  )
  await chmod(path.join(bin, 'gh'), 0o755)
  const scriptPath = path.join(root, 'step.sh')
  await writeFile(scriptPath, await stepScript(workflow, stepName))
  if (setup) await setup(root)

  const toBash = (value) => spawnSync(bash, ['--noprofile', '--norc', '-c', 'cd "$1" && pwd', '_', value], {
    encoding: 'utf8'
  }).stdout.trim()

  const result = spawnSync(
    bash,
    ['--noprofile', '--norc', '-c', 'export PATH="$1:$PATH"; set -e; source "$2"', '_', toBash(bin), 'step.sh'],
    {
      cwd: root,
      encoding: 'utf8',
      env: {
        ...process.env,
        GITHUB_REPOSITORY: 'Powerbouwer/power-platform-administration-tool',
        PR_NUMBER: '16',
        FAKE_GH_OUTPUT: path.join(root, 'gh-output.txt'),
        FAKE_GH_EXIT: String(ghExit),
        ...env
      }
    }
  )
  return { code: result.status, output: `${result.stdout}${result.stderr}` }
}

const scopes = [
  {
    workflow: 'validate-docs-scope.yml',
    step: 'Validate changed paths',
    allowed: ['docs/index.md', 'package.json'],
    blocked: 'solutions/ppat_core/file.yml'
  },
  {
    workflow: 'validate-project-scope.yml',
    step: 'Validate changed paths',
    allowed: ['.github/workflows/test.yml', 'README.md'],
    blocked: 'solutions/ppat_core/file.yml'
  }
]

for (const scope of scopes) {
  test(`${scope.workflow} skips an empty change set`, async () => {
    const result = await runStep(scope.workflow, scope.step)
    assert.equal(result.code, 0, result.output)
    assert.match(result.output, /no changed files; skipping/)
  })

  test(`${scope.workflow} fails when changed files cannot be retrieved`, async () => {
    for (const paths of [[], scope.allowed]) {
      const result = await runStep(scope.workflow, scope.step, { paths, ghExit: 1 })
      assert.equal(result.code, 1, result.output)
      assert.match(result.output, /Failed to retrieve changed pull request files/)
    }
  })

  test(`${scope.workflow} accepts allowed paths`, async () => {
    const result = await runStep(scope.workflow, scope.step, { paths: scope.allowed })
    assert.equal(result.code, 0, result.output)
    assert.match(result.output, /Validated 2 /)
  })

  test(`${scope.workflow} blocks disallowed current and previous paths`, async () => {
    const result = await runStep(scope.workflow, scope.step, {
      paths: [scope.allowed[0], scope.blocked]
    })
    assert.equal(result.code, 1, result.output)
    assert.match(result.output, new RegExp(scope.blocked))
  })
}

const devWorkflow = 'validate-dev-scope.yml'
const devStep = 'Validate branch route and changed paths'
const sprint = { HEAD_BRANCH: 'core/v1.0.0-spr-70', BASE_BRANCH: 'core/v1.0.0' }

async function solutionMetadata(root, version = '1.0.0.0') {
  const directory = path.join(root, 'solutions', 'ppat_core', 'solutions', 'ppat_core')
  await mkdir(directory, { recursive: true })
  await writeFile(
    path.join(directory, 'solution.yml'),
    `ImportExportXml:\n  SolutionManifest:\n    UniqueName: ppat_core\n    Version: ${version}\n`
  )
}

test('development scope skips an empty change set before route and metadata checks', async () => {
  const result = await runStep(devWorkflow, devStep, {
    env: { HEAD_BRANCH: 'core/v1.0.0-spr-70', BASE_BRANCH: 'main' }
  })
  assert.equal(result.code, 0, result.output)
  assert.match(result.output, /no changed files; skipping development scope validation/)
})

test('development scope fails when changed files cannot be retrieved', async () => {
  const result = await runStep(devWorkflow, devStep, { ghExit: 1, env: sprint })
  assert.equal(result.code, 1, result.output)
  assert.match(result.output, /Failed to retrieve changed pull request files/)
})

test('development scope keeps route and metadata checks for changes', async () => {
  const route = await runStep(devWorkflow, devStep, {
    paths: ['docs/index.md'],
    env: { ...sprint, BASE_BRANCH: 'main' }
  })
  assert.equal(route.code, 1, route.output)
  assert.match(route.output, /must target its matching core\/v1\.0\.0 release branch/)

  const metadata = await runStep(devWorkflow, devStep, { paths: ['docs/index.md'], env: sprint })
  assert.equal(metadata.code, 1, metadata.output)
  assert.match(metadata.output, /Solution metadata not found/)
})

test('development scope validates solution paths', { skip: !hasRuby && 'Ruby is not available' }, async () => {
  const allowed = await runStep(devWorkflow, devStep, {
    paths: ['solutions/ppat_core/file.yml', 'docs/index.md'],
    env: sprint,
    setup: solutionMetadata
  })
  assert.equal(allowed.code, 0, allowed.output)
  assert.match(allowed.output, /Validated 2 path entries for ppat_core/)

  const blocked = await runStep(devWorkflow, devStep, {
    paths: ['solutions/ppat_core/file.yml', 'solutions/ppat_change_viewer/file.yml'],
    env: sprint,
    setup: solutionMetadata
  })
  assert.equal(blocked.code, 1, blocked.output)
  assert.match(blocked.output, /solutions\/ppat_change_viewer\/file\.yml/)

  const version = await runStep(devWorkflow, devStep, {
    paths: ['solutions/ppat_core/file.yml'],
    env: sprint,
    setup: (root) => solutionMetadata(root, '1.0.1.0')
  })
  assert.equal(version.code, 1, version.output)
  assert.match(version.output, /Solution version must be 1\.0\.0\.0/)
})
