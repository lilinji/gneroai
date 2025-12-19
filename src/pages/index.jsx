import React, { useState } from 'react';
import Layout from '@theme/Layout';

import HeroSection from '../components/homepage/HeroSection';
import HomeFooter from '../components/homepage/HomeFooter';
import Head from '@docusaurus/Head';
import Link from '@docusaurus/Link';

export default function Homepage() {
  return (
    <Layout
      title="GneroAI平台文档"
      wrapperClassName="homepage flex flex-col"
      noFooter
    >
      <Head>
        <link rel="prefetch" href="/assets/css/elements.min.css" />
      </Head>
      <div>
        {/* <PhHelloBar /> */}

        {/* Code for Twilio credits banner */}

        {/* <div className="w-full bg-gradient-to-r from-blue-500 to-red-500 p-4 text-center font-medium text-white">
          Affected by Twilio Video Sunsetting? Migrate to Dyte and get upto
          $30,000 Credits{' '}
          <Link
            to="https://dyte.io/twilio-video-competitor"
            className="text-white underline"
          >
            Learn more
          </Link>
        </div> */}
      </div>

      <HeroSection />

      <HomeFooter />
    </Layout>
  );
}
