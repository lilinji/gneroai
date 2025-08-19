import React from 'react';
import Link from '@docusaurus/Link';
import {
  ArrowRightFilled,
  ServerRegular,
  FlashRegular,
  CloudRegular,
  DataUsageRegular,
  PersonRegular,
  ChartMultipleRegular,
} from '@fluentui/react-icons';
import clsx from 'clsx';

interface ClusterSpec {
  title: string;
  value: string;
  unit: string;
  icon: any;
  description: string;
}

interface Feature {
  title: string;
  icon: any;
  description: string;
  highlight?: boolean;
}

function SpecCard({ title, value, unit, icon: Icon, description }: ClusterSpec) {
  return (
    <div className="rounded-lg border border-secondary-700 bg-secondary-900 p-6 transition-all hover:border-primary hover:bg-secondary-800">
      <div className="mb-4 flex items-center gap-3">
        <Icon className="h-8 w-8 text-primary" />
        <div>
          <div className="text-2xl font-bold text-white">
            {value}
            <span className="ml-1 text-lg text-text-400">{unit}</span>
          </div>
          <div className="text-sm font-medium text-text-300">{title}</div>
        </div>
      </div>
      <p className="text-sm text-text-400">{description}</p>
    </div>
  );
}

function FeatureCard({ title, icon: Icon, description, highlight }: Feature) {
  return (
    <div className={clsx(
      "rounded-lg border p-6 transition-all",
      highlight 
        ? "border-primary bg-gradient-to-br from-primary/10 to-transparent" 
        : "border-secondary-700 bg-secondary-900 hover:border-primary"
    )}>
      <Icon className={clsx("mb-4 h-8 w-8", highlight ? "text-primary" : "text-text-300")} />
      <h4 className="mb-2 text-lg font-semibold text-white">{title}</h4>
      <p className="text-sm text-text-400">{description}</p>
    </div>
  );
}

export default function HPCFeaturesSection() {
  const clusterSpecs: ClusterSpec[] = [
    {
      title: 'CPU 总核数',
      value: '2000+',
      unit: '核',
      icon: ServerRegular,
      description: '高性能CPU计算核心，支持大规模并行计算任务',
    },
    {
      title: 'GPU 计算卡',
      value: '128',
      unit: '张',
      icon: FlashRegular,
      description: '包括V100、A100等高端GPU，专为AI和深度学习优化',
    },
    {
      title: '内存容量',
      value: '100+',
      unit: 'TB',
      icon: DataUsageRegular,
      description: '大容量内存支持内存密集型计算和大数据分析',
    },
    {
      title: '存储空间',
      value: '1+',
      unit: 'PB',
      icon: CloudRegular,
      description: '高速并行存储系统，保障数据安全和访问性能',
    },
  ];

  const features: Feature[] = [
    {
      title: '24/7 技术支持',
      icon: PersonRegular,
      description: '专业技术团队提供全天候支持，快速解决使用过程中的问题',
      highlight: true,
    },
    {
      title: '智能作业调度',
      icon: ChartMultipleRegular,
      description: 'SLURM调度系统智能分配资源，最大化集群利用率和计算效率',
    },
    {
      title: '数据安全保障',
      icon: CloudRegular,
      description: '多重备份机制和权限管控，确保研究数据的安全性和隐私性',
    },
  ];

  return (
    <section className="mx-auto mb-32 w-full max-w-6xl p-4 py-0">
      <div className="mb-12 text-center">
        <span className="mb-2 uppercase tracking-wider text-text-400">
          集群规格
        </span>
        <h3 className="mb-4 text-4xl font-bold">
          强大的计算基础设施
        </h3>
        <p className="mx-auto max-w-2xl text-text-400">
          太行I号提供业界领先的高性能计算资源，满足从小规模试验到大规模生产计算的各种需求
        </p>
      </div>

      {/* Cluster Specifications */}
      <div className="mb-16 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
        {clusterSpecs.map((spec) => (
          <SpecCard key={spec.title} {...spec} />
        ))}
      </div>

      {/* Platform Features */}
      <div>
        <div className="mb-8 flex items-center justify-between">
          <h4 className="text-2xl font-bold">平台特色</h4>
          <Link
            to="/guides/platform-overview"
            className="font-jakarta text-sm font-semibold text-primary"
          >
            了解更多特色 <ArrowRightFilled className="ml-1" />
          </Link>
        </div>
        
        <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
          {features.map((feature) => (
            <FeatureCard key={feature.title} {...feature} />
          ))}
        </div>
      </div>
    </section>
  );
}