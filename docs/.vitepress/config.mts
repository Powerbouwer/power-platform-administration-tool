import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Power Platform Administration Tool",
  description: "Open-source administration and governance toolkit for Microsoft Power Platform, built on the Power Platform Inventory API.",
  head: [
      ['link', { rel: 'icon', href: '/ppat-favicon.png' }],

      ['meta', { property: 'og:title', content: 'Power Platform Administration Tool' }],
      ['meta', { property: 'og:description', content: 'Open-source administration and governance toolkit for Microsoft Power Platform, built on the Power Platform Inventory API.' }],
      ['meta', { property: 'og:image', content: '/og-ppat.png' }],
      ['meta', { property: 'og:type', content: 'website' }],
    ],
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Modules', items: [
        { text: 'Inventory', link: '/inventory' },
        { text: 'Governance Processes', link: '/governance-processes' },
        { text: 'Maker Hub', link: '/maker-hub' },
        { text: 'Environment Settings Configurator', link: '/environment-settings-configurator' },
        { text: 'Tenant Monitor', link: '/tenant-monitor' },
        { text: 'Message Center Triage', link: '/message-center-triage' },
        { text: 'Maker Enablement', link: '/maker-enablement' },
        { text: 'Change Viewer', link: '/change-viewer' }
      ]},
      { text: 'Installation', link: '/installation' },
      { text: 'Architecture', link: '/architecture' },
      { text: 'Contributor Guide', link: '/developer' },
      { text: 'Team', link: '/team' }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Powerbouwer/power-platform-administration-tool' }
    ]
  }
})
