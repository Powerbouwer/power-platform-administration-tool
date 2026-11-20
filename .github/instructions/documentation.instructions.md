---
applyTo: "**/*.md"
---

When writing or editing Markdown:

- Before drafting, read `.vale.ini` and inspect the configured Vale rules and vocabulary relevant to the document. Treat them as writing constraints from the start. Don't wait for lint output to discover terminology, acronym, or style requirements.
- While drafting, use the configured rules and vocabulary to choose compliant wording. Run `npm run lint:vale` on the draft when practical, then revise it before considering the prose complete.
- Before completing a change, run:
  `npm run lint:vale`
- Fix all Vale errors introduced by your changes.
