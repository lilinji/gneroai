import React from 'react';
import Layout from '@theme-original/Layout';
import BackToTop from '@site/src/components/BackToTop';

export default function LayoutWrapper(props) {
  return (
    <>
      <Layout {...props} />
      <BackToTop />
    </>
  );
} 