import { createContentLoader } from 'vitepress'

export default createContentLoader('architecture/decisions/*/index.md', {
  transform: (pages) =>
    pages
      .map(({ url, frontmatter }) => ({ url, ...frontmatter }))
      .sort((a, b) => a.issue - b.issue)
})
