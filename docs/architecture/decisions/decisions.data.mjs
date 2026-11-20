import { createContentLoader } from "vitepress";

export default createContentLoader("architecture/decisions/*/index.md", {
  transform: (pages) =>
    pages
      .map(({ url, frontmatter }) => ({ url, ...frontmatter }))
      .sort(
        (leftDecision, rightDecision) =>
          leftDecision.issue - rightDecision.issue,
      ),
});
