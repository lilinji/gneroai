import React from 'react';
import Link from '@docusaurus/Link';
import {
  ArrowRightFilled,
  PersonRegular,
  BookRegular,
  PlayRegular,
} from '@fluentui/react-icons';

interface CTAStep {
  step: number;
  title: string;
  description: string;
  link: string;
  icon: any;
}

function StepCard({ step, title, description, link, icon: Icon }: CTAStep) {
  return (
    <Link
      to={link}
      className="group flex cursor-pointer flex-col rounded-lg border border-secondary-700 bg-secondary-900 p-6 text-inherit hover:border-primary hover:bg-secondary-800 hover:no-underline transition-all"
    >
      <div className="mb-4 flex items-center gap-4">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-white font-bold">
          {step}
        </div>
        <Icon className="h-6 w-6 text-primary" />
      </div>
      
      <h4 className="mb-2 text-lg font-semibold text-white group-hover:text-primary">
        {title}
      </h4>
      
      <p className="mb-4 flex-1 text-sm text-text-400">
        {description}
      </p>
      
      <div className="flex items-center text-sm font-medium text-primary">
        开始学习 <ArrowRightFilled className="ml-1 h-4 w-4" />
      </div>
    </Link>
  );
}

export default function GettingStartedCTA() {
  const steps: CTAStep[] = [
    {
      step: 1,
      title: '注册并登录平台',
      description: '通过Chess门户注册账号，获取平台访问权限，了解基本界面和功能。',
      link: '/guides/getting-started/overview',
      icon: PersonRegular,
    },
    {
      step: 2,
      title: '学习基础操作',
      description: '掌握文件管理、环境配置、模块加载等基本操作，熟悉平台使用流程。',
      link: '/guides/platform-overview/chess-portal',
      icon: BookRegular,
    },
    {
      step: 3,
      title: '提交第一个作业',
      description: '使用SLURM作业调度系统提交您的第一个计算任务，体验高性能计算。',
      link: '/guides/slurm-job-system/slurm-overview',
      icon: PlayRegular,
    },
  ];

  return (
    <section className="mx-auto mb-20 w-full max-w-6xl p-4">
      <div className="rounded-2xl bg-gradient-to-r from-primary/5 via-secondary-800 to-primary/5 p-8 md:p-12">
        <div className="mb-8 text-center">
          <h3 className="mb-4 text-3xl font-bold text-white md:text-4xl">
            开始您的 HPC 之旅
          </h3>
          <p className="mx-auto max-w-2xl text-text-300">
            三个简单步骤，快速上手太行I号智算平台，开启高性能计算体验
          </p>
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
          {steps.map((step) => (
            <StepCard key={step.step} {...step} />
          ))}
        </div>

        <div className="mt-8 text-center">
          <Link
            to="/guides"
            className="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-3 font-semibold text-white hover:bg-primary/90 hover:no-underline transition-colors"
          >
            查看完整教程
            <ArrowRightFilled className="h-4 w-4" />
          </Link>
        </div>
      </div>
    </section>
  );
}