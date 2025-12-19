import Link from '@docusaurus/Link';
import React, { useState } from 'react';
import clsx from 'clsx';
import {
  ArrowRightFilled,
  ChevronLeftRegular,
  ChevronRightRegular,
} from '@fluentui/react-icons';

interface Resource {
  url: string;
  type: string;
  title: string;
  description: string;
  image: string;
  duration: string;
}

const ALL_RESOURCES: Resource[] = [
  {
    url: '/guides/getting-started/overview',
    type: '教程',
    title: '太行I号平台快速入门',
    description:
      '从平台登录到运行第一个程序，全面了解GneroAI平台的使用方法和核心概念。',
    image:
      '/static/guides/hpc/platform-overview/chess-portal/login-page.png',
    duration: '5 分钟',
  },
  {
    url: '/guides/slurm-job-system/sbatch-examples',
    type: '教程',
    title: 'SLURM作业提交详解',
    description:
      '学习使用sbatch、srun和salloc命令进行作业提交，掌握资源管理和任务调度的关键技巧。',
    image:
      '/static/guides/hpc/sbatch-examples/sbatch.gif',
    duration: '8 分钟',
  },
  {
    url: '/guides/software-applications/alphafold3',
    type: '案例',
    title: 'AlphaFold3蛋白质结构预测',
    description: '使用AlphaFold3进行蛋白质结构预测的完整流程，包括数据准备、参数配置和结果分析。',
    image: '/static/guides/hpc/alphafold3/images/chess_platform_demo.gif',
    duration: '15 分钟',
  },
  {
    url: '/guides/runtime-environment/conda',
    type: '教程',
    title: 'Conda环境管理指南',
    description:
      '学习在HPC环境中使用Conda管理Python环境，包括环境创建、依赖安装和环境共享。',
    image:
      '/static/guides/hpc/platform-overview/chess-portal/dashboard-overview.png',
    duration: '6 分钟',
  },
  {
    url: '/guides/software-applications/vasp',
    type: '案例',
    title: 'VASP第一性原理计算',
    description: 'VASP量子化学计算软件的使用方法，包括输入文件准备、计算参数优化和结果分析。',
    image: '/static/guides/hpc/platform-overview/chess-portal/job-management.png',
    duration: '12 分钟',
  },
];

function Resource({
  type,
  url,
  image,
  title,
  description,
  duration,
}: Resource) {
  return (
    <Link
      className="fade-in group flex flex-col justify-between"
      key={title}
      href={url}
    >
      <div>
        <div className="mb-3 overflow-hidden rounded-lg">
          <img
            src={image}
            alt={title}
            loading="lazy"
            className="aspect-video h-full w-full object-cover transition-transform group-hover:scale-110"
          />
        </div>
        <h3 className="font-semibold text-black group-hover:text-primary dark:text-white dark:group-hover:text-primary-100 lg:text-xl">
          {title}
        </h3>
        <p className="leading-snug text-text-400">{description}</p>
      </div>
      <div className="mt-4 flex items-center justify-between">
        <div className="text-sm text-text-400">
          {`${duration} ${type === '案例' ? '实践' : '阅读'}`}
        </div>
      </div>
    </Link>
  );
}

export default function ResourcesSection() {
  const [page, setPage] = useState(1);
  const [activeType, setActiveType] = useState<'all' | '教程' | '案例'>('all');

  const resources =
    activeType === 'all'
      ? ALL_RESOURCES
      : ALL_RESOURCES.filter((r) => r.type === activeType);

  const currentResources = resources.slice((page - 1) * 3, page * 3);

  const pages = Math.ceil(resources.length / 3);

  const nextPage = () => {
    if (page < pages) {
      setPage(page + 1);
    }
  };

  const prevPage = () => {
    if (page > 1) {
      setPage(page - 1);
    }
  };

  return (
    <section className="no-underline-links my-20 px-6 ">
      <div className="mx-auto max-w-5xl">
        <div className="flex items-center justify-between">
          <div>
            <span className="dyte-badge">学习资源</span>
            <h2 className="mb-6 text-4xl">深入了解更多</h2>
          </div>
          <Link
            to="/guides"
            className="font-jakarta text-sm font-semibold text-primary"
          >
            查看所有教程 <ArrowRightFilled className="ml-1" />
          </Link>
        </div>

        <div className="mb-6 inline-flex gap-1 rounded-lg bg-secondary-700 p-2 font-jakarta text-sm font-semibold dark:bg-secondary-700">
          <button
            className={clsx(
              'rounded-lg px-4 py-2 transition-colors',
              activeType === 'all' &&
                'bg-zinc-700 text-white dark:bg-zinc-200 dark:text-black',
            )}
            onClick={() => setActiveType('all')}
          >
            全部
          </button>
          <button
            className={clsx(
              'rounded-lg px-4 py-2 transition-colors',
              activeType === '教程' &&
                'bg-zinc-700 text-white dark:bg-zinc-200 dark:text-black',
            )}
            onClick={() => setActiveType('教程')}
          >
            教程
          </button>
          <button
            className={clsx(
              'rounded-lg px-4 py-2 transition-colors',
              activeType === '案例' &&
                'bg-zinc-700 text-white dark:bg-zinc-200 dark:text-black',
            )}
            onClick={() => setActiveType('案例')}
          >
            案例
          </button>
        </div>

        <div className="relative flex flex-col">
          <div className="no-underline-links grid grid-cols-3 gap-6 sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
            {currentResources.map((resource, idx) => {
              return <Resource {...resource} key={idx} />;
            })}
          </div>

          <div className="my-10 ml-auto flex items-center justify-center md:my-0">
            <button
              onClick={prevPage}
              className="top-1/2 -left-14 rounded-lg bg-transparent p-1 hover:bg-secondary-800 md:absolute md:-translate-y-1/2"
            >
              <ChevronLeftRegular className="h-6 w-6" />
            </button>

            <button
              onClick={nextPage}
              className="top-1/2 -right-14 rounded-lg bg-transparent p-1 hover:bg-secondary-800 md:absolute md:-translate-y-1/2"
            >
              <ChevronRightRegular className="h-6 w-6" />
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
