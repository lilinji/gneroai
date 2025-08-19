import React from 'react';
import Link from '@docusaurus/Link';
import {
  ArrowRightFilled,
  ChartMultipleRegular,
  CodeRegular,
  DatabaseRegular,
  CloudRegular,
} from '@fluentui/react-icons';

interface Software {
  name: string;
  category: string;
  description: string;
  to?: string;
  icon: any;
  popular?: boolean;
}

function SoftwareCard({ name, category, description, to, icon: Icon, popular }: Software) {
  return (
    <Link
      to={to}
      className="group flex cursor-pointer flex-col rounded-lg border border-secondary-700 p-4 text-inherit hover:border-primary hover:text-primary hover:no-underline transition-all"
    >
      <div className="mb-3 flex items-center gap-3">
        <Icon className="h-6 w-6 text-primary" />
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <span className="font-semibold">{name}</span>
            {popular && (
              <span className="rounded-full bg-primary px-2 py-0.5 text-xs text-white">热门</span>
            )}
          </div>
          <div className="text-xs text-text-400">{category}</div>
        </div>
      </div>
      <p className="mb-0 text-sm text-text-400 group-hover:text-text-300">{description}</p>
    </Link>
  );
}

export default function HPCSoftware() {
  const aiSoftware: Software[] = [
    {
      name: 'AlphaFold3',
      category: '蛋白质结构预测',
      description: '谷歌DeepMind开发的最新蛋白质结构预测工具，支持复合物结构预测',
      to: '/guides/software-applications/alphafold3',
      icon: ChartMultipleRegular,
      popular: true,
    },
    {
      name: 'ParallelFold',
      category: '并行结构预测',
      description: '高性能并行化的AlphaFold结构预测工具，适合大规模批量计算',
      to: '/guides/software-applications/parallelfold',
      icon: CloudRegular,
      popular: true,
    },
    {
      name: 'Boltz-2',
      category: '生物分子建模',
      description: '先进的生物分子结构预测和建模软件',
      to: '/guides/software-applications/boltz2',
      icon: DatabaseRegular,
    },
    {
      name: 'Foldseek',
      category: '结构搜索',
      description: '快速蛋白质结构相似性搜索和比对工具',
      to: '/guides/software-applications/foldseek',
      icon: CodeRegular,
    },
  ];

  const scientificSoftware: Software[] = [
    {
      name: 'VASP',
      category: '量子化学计算',
      description: '维也纳从头计算软件包，广泛用于固体物理和材料科学研究',
      to: '/guides/software-applications/vasp',
      icon: ChartMultipleRegular,
      popular: true,
    },
    {
      name: 'Gaussian',
      category: '量子化学计算',
      description: '功能强大的量子化学计算软件，支持分子结构优化和性质计算',
      to: '/guides/software-applications/gaussian',
      icon: DatabaseRegular,
      popular: true,
    },
    {
      name: 'MATLAB',
      category: '数值计算',
      description: '数值计算、数据分析和算法开发的综合技术计算环境',
      to: '/guides/software-applications/matlab',
      icon: CodeRegular,
    },
    {
      name: 'VSCode',
      category: '开发环境',
      description: '在集群上的远程开发环境，支持代码编辑、调试和版本控制',
      to: '/guides/software-applications/vscode',
      icon: CloudRegular,
    },
  ];

  return (
    <section className="mx-auto mb-32 flex w-full max-w-6xl flex-col p-4 py-0">
      <span className="mb-2 uppercase tracking-wider text-text-400">
        科学计算软件
      </span>

      <div className="mb-12 flex items-center justify-between">
        <h3 className="text-4xl">
          丰富的软件生态系统
        </h3>
        
        <Link
          to="/guides/software-applications"
          className="font-jakarta text-sm font-semibold text-primary"
        >
          查看所有软件 <ArrowRightFilled className="ml-1" />
        </Link>
      </div>

      <div className="mb-10">
        <h4 className="mb-2 text-2xl">AI与生物计算</h4>

        <p className="mb-6 text-text-400">
          支持前沿的人工智能和生物信息学计算软件，包括蛋白质结构预测、
          <span className="font-semibold">分子建模</span>等领域的专业工具。
        </p>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {aiSoftware.map((software) => (
            <SoftwareCard key={software.name} {...software} />
          ))}
        </div>
      </div>

      <div>
        <h4 className="mb-2 text-2xl">传统科学计算</h4>

        <p className="mb-6 text-text-400">
          提供量子化学、数值计算、开发环境等
          <span className="font-semibold">经典科学计算</span>软件支持。
        </p>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {scientificSoftware.map((software) => (
            <SoftwareCard key={software.name} {...software} />
          ))}
        </div>
      </div>
    </section>
  );
}
