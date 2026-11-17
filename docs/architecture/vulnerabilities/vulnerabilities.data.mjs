import { createContentLoader } from "vitepress";

export default createContentLoader("architecture/vulnerabilities/*/index.md", {
  transform: (pages) =>
    pages
      .map(({ url, frontmatter }) => ({ url, ...frontmatter }))
      .sort((leftVulnerability, rightVulnerability) =>
        String(leftVulnerability.ghsa ?? "").localeCompare(
          String(rightVulnerability.ghsa ?? ""),
        ),
      ),
});
