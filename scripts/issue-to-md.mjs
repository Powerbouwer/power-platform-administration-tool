import {
  appendFileSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { dirname } from "node:path";

const createBodyField = (issue) => {
    // Normalize line endings to Line Feed for consistent parsing of sections
    const body = issue.body.replace(/\r\n?/gu, "\n");
    return (label) => {
      // Split the body into sections based on the issue template headings
      const [, section = ""] = body.split(`### ${label}\n`),
        result = section.split(/^### /mu).shift().trim();
      if (result === "_No response_") {
        return "";
      }
      return result;
    };
  },
  createDocument = {
    ADR: (issue) => {
      // Remove the [ADR] prefix from the issue title if present to get the ADR title
      const adrTitle = issue.title.replace(/^.*?\[ADR\] /su, ""),
        field = createBodyField(issue),
        // Generate a URL-friendly slug from the ADR title
        slug = adrTitle
          .toLowerCase()
          // Replace groups of spaces, punctuation, and other non-ASCII characters with one hyphen.
          .replace(/[^a-z0-9]+/gu, "-")
          // Remove hyphens from the beginning and end.
          .replace(/^-+|-+$/gu, "");

      return {
        branch: `adr-${slug}`,
        content:
          // Front matter for the ADR document
          `---\n${[
            ["title", adrTitle],
            ["issue", issue.number],
            ["issueUrl", issue.html_url],
            ["scope", field("Scope")],
            ["decisionDate", issue.closed_at.split("T").shift()],
          ]
            .map(([key, value]) => `${key}: ${JSON.stringify(value)}`)
            .join("\n")}\n---\n\n` +
          // Main content for the ADR document follows the front matter
          `# ${adrTitle}\n\n` +
          `Source: [Issue #${issue.number}](${issue.html_url})\n\n${issue.body}\n`,
        path: `docs/architecture/decisions/${slug}/index.md`,
        title: `Document ADR from issue #${issue.number}`,
      };
    },
    vulnerability: (issue) => {
      const field = createBodyField(issue);

      return {
        branch: field("Advisory identifier").toLowerCase(),
        content:
          // Front matter for the vulnerability document
          `---\n${[
            ["ghsa", field("Advisory identifier").toUpperCase()],
            ["issue", issue.number],
            ["issueUrl", issue.html_url],
            ["severity", field("Severity")],
            ["affectedPackage", field("Affected package")],
            ["installedVersion", field("Installed version")],
            ["dependencyType", field("Dependency type")],
            ["usage", field("Usage")],
            ["proposedDecision", field("Proposed decision")],
            ["proposedExpiry", field("Proposed expiry")],
            ["decisionDate", issue.closed_at.split("T").shift()],
          ]
            .map(([key, value]) => `${key}: ${JSON.stringify(value)}`)
            .join("\n")}\n---\n\n` +
          // Main content for the vulnerability document follows the front matter
          `# ${field("Advisory identifier").toUpperCase()}\n\n` +
          `Source: [Issue #${issue.number}](${issue.html_url})\n\n${issue.body}\n`,
        path: `docs/architecture/vulnerabilities/${field("Advisory identifier")}/index.md`,
        title: `Document GHSA from issue #${issue.number}`,
      };
    },
  },
  generateDocument = (document) => {
    mkdirSync(dirname(document.path), { recursive: true });
    writeFileSync(document.path, document.content);
    appendFileSync(
      process.env.GITHUB_OUTPUT,
      `branch=${document.branch}\npath=${document.path}\n` +
        `title=${document.title}\n`,
    );
  };

{
  const { issue } = JSON.parse(
    readFileSync(process.env.GITHUB_EVENT_PATH, "utf8"),
  );
  generateDocument(createDocument[issue.type.name](issue));
}
