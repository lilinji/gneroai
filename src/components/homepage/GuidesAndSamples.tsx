import React from 'react';
import Link from '@docusaurus/Link';
import {
  AppsAddInRegular,
  ArrowRightFilled,
  DocumentRegular,
  OpenRegular,
  ServerRegular,
  CodeRegular,
  CloudRegular,
  ChartMultipleFilled,
  DatabaseRegular,
} from '@fluentui/react-icons';
import clsx from 'clsx';
import { ChevronRight, GitHub } from 'react-feather';

interface Guide {
  title: string;
  icon: any;
  text: string;
  link: string;
}

const guides: Guide[] = [
  {
    title: '平台概览',
    icon: ServerRegular,
    text: '了解太行I号平台的基本概念、Chess门户使用和集群配置。',
    link: '/guides/platform-overview/chess-portal',
  },
  {
    title: '运行环境',
    icon: CloudRegular,
    text: '学习Conda环境、模块系统、Singularity容器的使用方法。',
    link: '/guides/runtime-environment/conda',
  },
  {
    title: '作业调度',
    icon: ChartMultipleFilled,
    text: '掌握SLURM作业提交、资源管理和任务调度技巧。',
    link: '/guides/slurm-job-system/slurm-overview',
  },
  {
    title: '科学计算软件',
    icon: CodeRegular,
    text: '使用AlphaFold、VASP、Gaussian等专业科学计算软件。',
    link: '/guides/software-applications/overview',
  },
];

interface Sample {
  title: string;
  type?: string;
  description?: string;
  link?: string;
  size?: string;
}

const samples: Sample[] = [
  {
    title: 'Sbatch作业脚本示例',
    type: 'Shell脚本',
    description: '标准的SLURM批处理作业提交脚本模板',
    link: '/guides/slurm-job-system/sbatch-examples',
    size: '1KB',
  },
  {
    title: 'AlphaFold3预测脚本',
    type: '蛋白质预测',
    description: '使用AlphaFold3进行蛋白质结构预测的完整流程',
    link: '/guides/software-applications/alphafold3',
    size: '5KB',
  },
  {
    title: 'VASP计算配置',
    type: '量子化学',
    description: 'VASP第一性原理计算的输入文件和参数配置',
    link: '/guides/software-applications/vasp',
    size: '2KB',
  },
  {
    title: 'Conda环境配置',
    type: 'YAML配置',
    description: '常用的科学计算环境配置文件模板',
    link: '/guides/runtime-environment/conda',
    size: '3KB',
  },
];

function Guide({ title, text, icon: Icon, link }: (typeof guides)[0]) {
  return (
    <Link
      to={link}
      className="group flex cursor-pointer items-start gap-2 rounded-lg border-2 border-transparent p-3 text-inherit transition-colors hover:border-primary hover:text-primary"
    >
      <Icon className="h-6 w-6" />

      <div className="flex flex-col">
        <h4 className="mb-1 font-semibold">{title}</h4>
        <p className="mb-0 text-sm text-text-400">{text}</p>
      </div>

      <ChevronRight className="ml-auto h-5 w-5 self-center opacity-0 transition-opacity group-hover:opacity-100" />
    </Link>
  );
}

function Sample({ title, type, description, link, size }: Sample) {
  return (
    <Link
      to={link}
      className="group flex cursor-pointer items-start justify-between rounded-lg border-2 border-transparent p-3 text-text-400/60 transition-colors hover:border-primary hover:text-primary hover:no-underline"
    >
      <div className="flex flex-col flex-1 mr-3">
        <h4 className="mb-1 text-black group-hover:text-primary dark:text-white">
          {title}
        </h4>
        <div className="text-sm text-text-400 mb-1">{type}</div>
        <div className="text-xs text-text-400">{description}</div>
      </div>

      <div className="flex items-center gap-2.5 flex-shrink-0">
        <div className="text-xs text-text-400">{size}</div>
        <div className="flex items-center gap-1 rounded-lg py-1 px-3 text-inherit transition-colors group-hover:bg-primary group-hover:text-white">
          <DocumentRegular className="h-4 w-4" />
          <span className="font-semibold text-xs">查看</span>
        </div>
      </div>
    </Link>
  );
}

export default function GuidesAndSamples() {
  return (
    <section className="no-underline-links my-40 mx-auto flex w-full max-w-5xl flex-col gap-10 p-4 py-0 md:flex-row md:gap-0">
      <div className="flex-1">
        <div className="mb-8 flex items-center justify-between">
          <h3 className="m-0">热门使用指南</h3>

          <Link to="/guides" className="font-jakarta text-sm font-semibold">
            查看更多指南 <ArrowRightFilled className="ml-1" />
          </Link>
        </div>

        <div className="flex flex-col gap-4">
          {guides.map((guide) => (
            <Guide {...guide} key={guide.title} />
          ))}
        </div>
      </div>

      <div
        className={clsx(
          'mx-8 block flex-shrink-0 bg-gradient-to-b from-transparent via-secondary-700 to-transparent',
          'hidden w-px md:block',
        )}
      />

      <div className="w-full md:max-w-sm">
        <div className="mb-8 flex items-center justify-between">
          <h3 className="m-0">示例与模板</h3>

          <Link
            to="/guides/software-applications"
            className="font-jakarta text-sm font-semibold"
          >
            查看所有示例 <ArrowRightFilled className="ml-1" />
          </Link>
        </div>

        <div className="flex flex-col gap-4">
          {samples.map((sample) => (
            <Sample {...sample} key={sample.title} />
          ))}
        </div>
      </div>
    </section>
  );
}
