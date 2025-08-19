import React from 'react';
import Link from '@docusaurus/Link';
import {
  ServerRegular,
  ChartMultipleRegular,
  CodeRegular,
  CloudRegular,
} from '@fluentui/react-icons';
import ThemedImage from '@theme/ThemedImage';
import clsx from 'clsx';

const PRODUCTS = [
  {
    title: '高性能集群',
    link: '/guides/platform-overview/chess-portal',
    icon: ServerRegular,
    lightImage: '/static/landing-page/hero/video-graphic.png',
    darkImage: '/static/landing-page/hero/video-graphic-dark.png',
    text: '太行I号超级计算机提供强大的并行计算能力，支持大规模科学计算和深度学习任务，满足各类研究需求。',
  },
  {
    title: '科学计算软件',
    link: '/guides/software-applications/overview',
    icon: CodeRegular,
    lightImage: '/static/landing-page/hero/voice-graphic.png',
    darkImage: '/static/landing-page/hero/voice-graphic-dark.png',
    text: '提供丰富的科学计算软件生态，包括AlphaFold3、VASP、Gaussian、MATLAB、ParallelFold等前沿应用。',
  },
  {
    title: '作业调度系统',
    link: '/guides/slurm-job-system/slurm-overview',
    icon: ChartMultipleRegular,
    lightImage: '/static/landing-page/hero/livestream-graphic.png',
    darkImage: '/static/landing-page/hero/livestream-graphic-dark.png',
    text: '基于SLURM的智能作业调度系统，支持批处理、交互式和实时作业提交，高效管理计算资源。',
  },
];

function HeroProduct({
  link,
  title,
  icon: Icon,
  text,
  lightImage,
  darkImage,
}: (typeof PRODUCTS)[0]) {
  return (
    <Link
      to={link}
      style={{
        borderWidth: '1px',
      }}
      className={clsx(
        'group cursor-pointer overflow-clip rounded-3xl from-primary/30 via-transparent to-transparent text-black transition-all hover:bg-gradient-to-tr hover:text-primary hover:no-underline dark:text-white',
        'w-[90vw] border-secondary-700 bg-secondary-900 hover:!border-primary dark:border-secondary-800 sm:w-[440px]',
      )}
    >
      <div className="p-6 !pb-0">
        <h3 className="mb-1.5 flex items-center gap-3 font-jakarta group-hover:text-primary">
          <Icon className="h-7 w-7" />
          <div>
            {title}
            {/* {beta && <span className="font-normal text-text-400"> (Beta)</span>} */}
          </div>
        </h3>
        <p className="mb-0 text-sm text-zinc-400">{text}</p>
      </div>
      <ThemedImage
        sources={{
          light: lightImage,
          dark: darkImage,
        }}
        alt={title}
        className="mt-1 w-full transition-transform group-hover:scale-110"
      />
    </Link>
  );
}

export default function HeroSection() {
  return (
    <div className="noise-bg pb-14">
      <section className="no-underline-links px-4 pt-16 lg:py-0">
        <div className="flex flex-col items-center justify-between py-14">
          <h2 className="mb-4 font-jakarta text-5xl font-bold">
            太行I号智算平台
          </h2>
          <p className="max-w-xl text-center text-text-400">
            提供高性能计算服务，支持科学计算、深度学习和大数据分析。
            通过丰富的软件生态和灵活的资源调度，助力科研创新和技术突破。
          </p>
        </div>
      </section>

      <section className="mx-auto flex w-full max-w-6xl flex-wrap justify-center gap-6 px-4">
        {PRODUCTS.map((product) => (
          <HeroProduct {...product} key={product.title} />
        ))}
      </section>
    </div>
  );
}
