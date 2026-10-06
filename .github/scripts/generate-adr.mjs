import { mkdir, readFile, readdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const REQUIRED_FIELDS = [
  'Scope',
  'Context and problem statement',
  'Decision drivers',
  'Considered options',
  'Decision outcome',
  'Consequences'
]

const OPTIONAL_FIELDS = ['Participants', 'Links']
const INDEX_START = '<!-- ADR-LIST:START -->'
const INDEX_END = '<!-- ADR-LIST:END -->'

export function parseIssueForm(body) {
  const fields = new Map()
  const headingPattern = /^### (.+)\r?$/gm
  const headings = [...body.matchAll(headingPattern)]

  for (const [index, heading] of headings.entries()) {
    const valueStart = heading.index + heading[0].length
    const valueEnd = headings[index + 1]?.index ?? body.length
    const value = body.slice(valueStart, valueEnd).trim()

    fields.set(heading[1].trim(), value === '_No response_' ? '' : value)
  }

  const missing = REQUIRED_FIELDS.filter((field) => !fields.get(field))
  if (missing.length > 0) {
    throw new Error(`Missing required ADR fields: ${missing.join(', ')}`)
  }

  return Object.fromEntries(
    [...REQUIRED_FIELDS, ...OPTIONAL_FIELDS].map((field) => [field, fields.get(field) ?? ''])
  )
}

export function isAdrIssue(issue) {
  const issueType = typeof issue.type === 'string' ? issue.type : issue.type?.name

  return issueType?.toLowerCase() === 'adr'
}

export function mapScope(scope) {
  const scopes = {
    'Repository-wide': { scope: 'repository' },
    Core: { scope: 'solution', solution: 'ppat_core' },
    'Change Viewer': { scope: 'solution', solution: 'ppat_change_viewer' }
  }
  const mapped = scopes[scope]

  if (!mapped) {
    throw new Error(`Unsupported ADR scope: ${scope}`)
  }

  return mapped
}

export function slugify(value) {
  const slug = value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 80)
    .replace(/-$/g, '')

  return slug || 'architecture-decision'
}

function yamlString(value) {
  return JSON.stringify(value)
}

function dateOnly(value, fieldName) {
  if (!value || Number.isNaN(Date.parse(value))) {
    throw new Error(`Issue ${fieldName} is missing or invalid`)
  }

  return new Date(value).toISOString().slice(0, 10)
}

export function validateAdrIssue(issue) {
  if (!isAdrIssue(issue)) {
    throw new Error('Issue is not an ADR')
  }

  const fields = parseIssueForm(issue.body ?? '')
  const mappedScope = mapScope(fields.Scope)
  const title = issue.title.replace(/^🧭 \[ADR\]\s*/, '').trim()

  if (!title) {
    throw new Error('ADR title is empty')
  }

  dateOnly(issue.created_at, 'created_at')

  return { fields, mappedScope, title }
}

export function createAdr(issue) {
  const { fields, mappedScope, title } = validateAdrIssue(issue)

  const frontmatter = [
    '---',
    `title: ${yamlString(title)}`,
    'status: accepted',
    `scope: ${mappedScope.scope}`,
    ...(mappedScope.solution ? [`solution: ${mappedScope.solution}`] : []),
    `proposedDate: ${dateOnly(issue.created_at, 'created_at')}`,
    `decisionDate: ${dateOnly(issue.closed_at, 'closed_at')}`,
    `issue: ${issue.number}`,
    '---'
  ]
  const sections = [
    `# ${title}`,
    `## Context and problem statement\n\n${fields['Context and problem statement']}`,
    `## Decision drivers\n\n${fields['Decision drivers']}`,
    `## Considered options\n\n${fields['Considered options']}`,
    `## Decision outcome\n\n${fields['Decision outcome']}`,
    `## Consequences\n\n${fields.Consequences}`,
    ...(fields.Participants ? [`## Participants\n\n${fields.Participants}`] : []),
    ...(fields.Links ? [`## Links\n\n${fields.Links}`] : [])
  ]

  return {
    fileName: `issue-${issue.number}-${slugify(title)}.md`,
    content: `${frontmatter.join('\n')}\n\n${sections.join('\n\n')}\n`,
    metadata: {
      issue: issue.number,
      title,
      scope: mappedScope.solution ?? 'Repository-wide',
      decisionDate: dateOnly(issue.closed_at, 'closed_at')
    }
  }
}

export function validateAdrEvent(event) {
  if (!event.issue) {
    throw new Error('Event does not contain an issue')
  }
  if (event.action !== 'closed') {
    throw new Error('ADR event action must be closed')
  }
  if (event.issue.state_reason !== 'completed') {
    throw new Error('ADR issue must be closed as completed')
  }

  return createAdr(event.issue)
}

function readFrontmatter(markdown) {
  const match = markdown.match(/^---\r?\n([\s\S]*?)\r?\n---/)
  if (!match) return null

  const values = Object.fromEntries(
    match[1].split(/\r?\n/).map((line) => {
      const separator = line.indexOf(':')
      const key = line.slice(0, separator)
      const rawValue = line.slice(separator + 1).trim()
      let value = rawValue

      if (rawValue.startsWith('"')) {
        value = JSON.parse(rawValue)
      } else if (/^\d+$/.test(rawValue)) {
        value = Number(rawValue)
      }

      return [key, value]
    })
  )

  return values
}

export async function updateIndex(rootDirectory, indexPath) {
  const decisionsDirectory = path.join(rootDirectory, 'docs', 'architecture', 'decisions')
  const files = (await readdir(decisionsDirectory)).filter((file) => file.endsWith('.md')).sort()
  const records = []

  for (const file of files) {
    const markdown = await readFile(path.join(decisionsDirectory, file), 'utf8')
    const metadata = readFrontmatter(markdown)
    if (!metadata) continue

    records.push({ file, ...metadata })
  }

  records.sort((left, right) => Number(left.issue) - Number(right.issue))
  const rows = records.map((record) => {
    const scope = record.scope === 'repository' ? 'Repository-wide' : record.solution
    const link = `./decisions/${record.file.replace(/\.md$/, '')}`
    return `| ${record.issue} | [${record.title}](${link}) | ${scope} | ${record.decisionDate} |`
  })
  const generated = [
    INDEX_START,
    '| ADR | Decision | Scope | Decision date |',
    '| ---: | --- | --- | --- |',
    ...rows,
    INDEX_END
  ].join('\n')
  const current = await readFile(indexPath, 'utf8')
  const pattern = new RegExp(`${INDEX_START}[\\s\\S]*?${INDEX_END}`)

  if (!pattern.test(current)) {
    throw new Error(`ADR index markers are missing from ${indexPath}`)
  }

  await writeFile(indexPath, current.replace(pattern, generated))
}

export async function generateFromEvent(event, rootDirectory = process.cwd()) {
  const issue = event.issue
  if (!issue || event.action !== 'closed' || issue.state_reason !== 'completed' || !isAdrIssue(issue)) {
    return null
  }

  const adr = validateAdrEvent(event)
  const decisionsDirectory = path.join(rootDirectory, 'docs', 'architecture', 'decisions')
  const outputPath = path.join(decisionsDirectory, adr.fileName)
  await mkdir(decisionsDirectory, { recursive: true })
  await writeFile(outputPath, adr.content)
  await updateIndex(rootDirectory, path.join(rootDirectory, 'docs', 'architecture', 'index.md'))

  return { ...adr, outputPath }
}

async function main() {
  const validateOnly = process.argv.includes('--validate')
  const eventPath = process.env.GITHUB_EVENT_PATH ?? process.argv.slice(2).find((argument) => argument !== '--validate')
  if (!eventPath) {
    throw new Error('GITHUB_EVENT_PATH or an event file argument is required')
  }

  const event = JSON.parse(await readFile(eventPath, 'utf8'))
  if (validateOnly) {
    if (!event.issue) {
      throw new Error('Event does not contain an issue')
    }

    validateAdrIssue(event.issue)
    console.log('ADR issue structure is valid.')
    return
  }

  const result = await generateFromEvent(event)
  if (!result) {
    console.log('No ADR generated for this event.')
    return
  }

  console.log(`Generated ${path.relative(process.cwd(), result.outputPath)}`)
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message)
    process.exitCode = 1
  })
}