/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  bookSidebar: [
    'preface',
    {
      type: 'category',
      label: 'Part 1: Architecture — How Claude Code Works',
      items: [
        'part1/ch01',
        'part1/ch02',
        'part1/ch03',
        'part1/ch04',
      ],
    },
    {
      type: 'category',
      label: 'Part 2: Prompt Engineering — System Prompts as Control Plane',
      items: [
        'part2/ch05',
        'part2/ch06',
        'part2/ch07',
        'part2/ch08',
      ],
    },
    {
      type: 'category',
      label: 'Part 3: Context Management — 200K Token Arena',
      items: [
        'part3/ch09',
        'part3/ch10',
        'part3/ch11',
        'part3/ch12',
      ],
    },
    {
      type: 'category',
      label: 'Part 4: Prompt Caching — Hidden Cost Optimizer',
      items: [
        'part4/ch13',
        'part4/ch14',
        'part4/ch15',
      ],
    },
    {
      type: 'category',
      label: 'Part 5: Security & Permissions — Defense in Depth',
      items: [
        'part5/ch16',
        'part5/ch17',
        'part5/ch18',
        'part5/ch19',
      ],
    },
    {
      type: 'category',
      label: 'Part 6: Advanced Subsystems',
      items: [
        'part6/ch20',
        'part6/ch21',
        'part6/ch22',
        'part6/ch23',
      ],
    },
    {
      type: 'category',
      label: 'Part 7: Lessons for AI Agent Builders',
      items: [
        'part7/ch24',
        'part7/ch25',
        'part7/ch26',
        'part7/ch27',
      ],
    },
    {
      type: 'category',
      label: 'Appendix',
      items: [
        'appendix/a-file-index',
        'appendix/b-env-vars',
        'appendix/c-glossary',
        'appendix/d-feature-flags',
      ],
    },
  ],
};

module.exports = sidebars;
