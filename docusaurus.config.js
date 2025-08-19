const { themes } = require('prism-react-renderer');

const code_themes = {
  light: themes.github,
  dark: themes.dracula,
};

/** @type {import('@docusaurus/types').Config} */
const meta = {
  title: '太行I号智算平台文档',
  tagline:
    '太行I号高性能计算平台的综合文档，包括使用指南、参考资料和最佳实践。',
  url: 'https://hpc.biodesign.ac.cn',
  baseUrl: '/',
  favicon: '/favicon.ico',
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
};

/** @type {import('@docusaurus/plugin-content-docs').Options[]} */
const docs = [
  // Only include the guides section which exists
  // The CLI and plugin-sdk folders don't exist, so they're removed
];

/** @type {import('@docusaurus/plugin-content-docs').Options} */
const defaultSettings = {
  breadcrumbs: true,
  editUrl: 'https://github.com/tib-hpc/docs/tree/main/',
  showLastUpdateTime: true,
  sidebarCollapsible: true,
  remarkPlugins: [
    [require('@docusaurus/remark-plugin-npm2yarn'), { sync: true }],
  ],
  sidebarPath: require.resolve('./sidebars-default.js'),
};

/**
 * Create a section
 * @param {import('@docusaurus/plugin-content-docs').Options} options
 */
function create_doc_plugin({
  sidebarPath = require.resolve('./sidebars-default.js'),
  ...options
}) {
  return [
    '@docusaurus/plugin-content-docs',
    /** @type {import('@docusaurus/plugin-content-docs').Options} */
    ({
      ...defaultSettings,
      sidebarPath,
      ...options,
    }),
  ];
}

const { webpackPlugin } = require('./plugins/webpack-plugin.cjs');
const tailwindPlugin = require('./plugins/tailwind-plugin.cjs');
const docs_plugins = docs.map((doc) => create_doc_plugin(doc));

const plugins = [
  tailwindPlugin,
  ...docs_plugins,
  webpackPlugin,
  [
    '@docusaurus/plugin-client-redirects',
    {
      createRedirects(path) {
        // Keep only essential redirects for HPC documentation
        if (path.startsWith('/guides/capabilities')) {
          return [path.replace('/guides/capabilities', '/guides/features')];
        }
        return undefined;
      },
    },
  ],
];

const fs = require('fs');
// const resourcesHTML = fs.readFileSync('./src/snippets/resources.html', 'utf-8');



/** @type {import('@docusaurus/types').Config} */
const config = {
  ...meta,
  plugins,
  future: {
    experimental_faster: true,
    v4: true,
  },

  // Handle broken anchors gracefully - mostly legacy Dyte SDK links
  onBrokenAnchors: 'warn',
  onBrokenLinks: 'warn',

  trailingSlash: false,
  themes: ['@docusaurus/theme-live-codeblock', '@docusaurus/theme-mermaid'],
  clientModules: [],
  scripts: process.env.NODE_ENV === 'production' 
    ? [{ src: 'https://cdn.statuspage.io/se-v2.js', async: true }]
    : [],
  markdown: {
    mermaid: true,
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          path: 'docs/guides',
          id: 'guides',
          routeBasePath: '/guides',
          versions: {
            current: {
              label: '1.0.0',
            },
          },
          ...defaultSettings,
        },
        blog: false,
        theme: {
          customCss: [
            require.resolve('./src/css/custom.css'),
            require.resolve('./src/css/api-reference.css'),
          ],
        },
        sitemap: {
          ignorePatterns: ['**/tags/**', '/api/*'],
        },
        googleTagManager: {
          containerId: 'GTM-5FDFFSS',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: '/img/dyte-docs-card.png',
      colorMode: {
        defaultMode: 'light',
      },
      docs: {
        sidebar: {
          autoCollapseCategories: true,
          hideable: true,
        },
      },
      navbar: {
        logo: {
          href: '/',
          src: '/logo/light.svg',
          srcDark: '/logo/dark.svg',
          alt: 'Dyte Documentation | Dyte Docs',
          height: '40px',
          width: '101px',
        },
        items: [
          {
            label: 'Guides',
            to: 'guides',
            className: 'guides-top-header',
          },

          // {
          //   label: 'REST API',
          //   to: '/api/',
          // },
          // {
          //   label: 'Resources',
          //   type: 'dropdown',
          //   className: 'dyte-dropdown resources-dropdown',
          //   items: [
          //     {
          //       type: 'html',
          //       value: resourcesHTML,
          //       className: 'dyte-dropdown',
          //     },
          //   ],
          // },
          {
            label: 'Support',
            to: 'https://www.biodesign.ac.cn/feedback2',
          },

          {
            type: 'search',
            position: 'right',
          },
          // {
          //   label: 'Book a demo',
          //   href: 'https://dyte.io/schedule-demo',
          //   position: 'right',
          //   className: 'navbar-book-demo',
          // },
          {
            label: 'Sign Up',
            href: 'https://www.biodesign.ac.cn/signin',
            position: 'right',
            className: 'dev-portal-signup dev-portal-link',
          },
        ],
      },
      footer: {
        logo: {
          href: '/',
          src: '/logo/light.svg',
          srcDark: '/logo/dark.svg',
          alt: 'Dyte Documentation | Dyte Docs',
          height: '36px',
        },
        links: [
          {
            title: '平台相关',
            items: [
              {
                label: '平台主页',
                href: 'https://hpc.biodesign.ac.cn',
              },
              {
                label: '用户反馈',
                href: 'https://www.biodesign.ac.cn/feedback2',
              },
              {
                label: '账号注册',
                href: 'https://www.biodesign.ac.cn/signin',
              },
            ],
          },
          {
            title: '支持',
            items: [
              {
                label: '技术支持',
                href: 'https://www.biodesign.ac.cn/feedback2',
              },
              {
                label: '用户手册',
                href: '/',
              },
            ],
          },
        ],
        copyright: 'Copyright © 太行I号智算平台 2024. All rights reserved.',
      },
      prism: {
        theme: code_themes.light,
        darkTheme: code_themes.dark,
        additionalLanguages: [
          'dart',
          'ruby',
          'groovy',
          'kotlin',
          'java',
          'swift',
          'objectivec',
          'json',
          'bash',
        ],
        magicComments: [
          {
            className: 'theme-code-block-highlighted-line',
            line: 'highlight-next-line',
            block: { start: 'highlight-start', end: 'highlight-end' },
          },
          {
            className: 'code-block-error-line',
            line: 'highlight-next-line-error',
          },
        ],
      },
      // Algolia search configuration - update with your own credentials
      algolia: {
        appId: 'YOUR_ALGOLIA_APP_ID',
        apiKey: 'YOUR_ALGOLIA_SEARCH_KEY',
        indexName: 'tibhpc-docs',
        contextualSearch: true,
        searchParameters: {},
      },
    }),

  // webpack: {
  //   jsLoader: (isServer) => ({
  //     loader: require.resolve('swc-loader'),
  //     options: {
  //       jsc: {
  //         parser: {
  //           syntax: 'typescript',
  //           tsx: true,
  //         },
  //         target: 'es2017',
  //       },
  //       module: {
  //         type: isServer ? 'commonjs' : 'es6',
  //       },
  //     },
  //   }),
  // },
};

module.exports = config;
