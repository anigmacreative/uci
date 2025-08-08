/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
    serverComponentsExternalPackages: ['sharp', 'onnxruntime-node'],
  },
  
  // Performance optimizations
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  
  // Image optimization
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.tiktokcdn.com',
      },
      {
        protocol: 'https',
        hostname: '**.instagram.com',
      },
      {
        protocol: 'https',
        hostname: '**.youtube.com',
      },
      {
        protocol: 'https',
        hostname: '**.linkedin.com',
      },
      {
        protocol: 'https',
        hostname: 'ipfs.io',
      },
      {
        protocol: 'https',
        hostname: '**.amazonaws.com',
      }
    ],
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },
  
  // Security headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ];
  },
  
  // API routes configuration
  async rewrites() {
    return [
      {
        source: '/api/blockchain/:path*',
        destination: '/api/blockchain/:path*',
      },
      {
        source: '/api/platforms/:path*',
        destination: '/api/platforms/:path*',
      },
      {
        source: '/api/identity/:path*',
        destination: '/api/identity/:path*',
      },
    ];
  },
  
  // WebSocket support
  webpack: (config, { dev, isServer }) => {
    // Handle web3 and blockchain libraries
    config.resolve.fallback = {
      ...config.resolve.fallback,
      fs: false,
      net: false,
      tls: false,
      crypto: require.resolve('crypto-browserify'),
      stream: require.resolve('stream-browserify'),
      url: require.resolve('url'),
      zlib: require.resolve('browserify-zlib'),
      http: require.resolve('stream-http'),
      https: require.resolve('https-browserify'),
      assert: require.resolve('assert'),
      os: require.resolve('os-browserify/browser'),
      path: require.resolve('path-browserify'),
    };
    
    // Ignore canvas for server-side rendering (face-api.js)
    if (isServer) {
      config.externals.push('canvas');
    }
    
    // WebAssembly support for ML models
    config.experiments = {
      asyncWebAssembly: true,
      layers: true,
    };
    
    return config;
  },
  
  // Environment variables
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },
  
  // Enable source maps in production for better debugging
  productionBrowserSourceMaps: true,
  
  // Optimize bundle size
  compress: true,
  
  // Enable experimental features
  experimental: {
    optimizeCss: true,
    scrollRestoration: true,
    swcMinify: true,
  },
};

module.exports = nextConfig;