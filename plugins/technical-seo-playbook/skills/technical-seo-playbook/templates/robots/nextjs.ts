// app/robots.ts — Next.js App Router programmatic robots.txt
// See: https://nextjs.org/docs/app/api-reference/file-conventions/metadata/robots
import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/api/', '/admin/', '/*?utm_'],
      },
      // AI crawlers — opt out per crawler
      { userAgent: 'GPTBot', disallow: '/' },
      { userAgent: 'ClaudeBot', disallow: '/' },
      { userAgent: 'PerplexityBot', disallow: '/' },
      // Google-Extended controls Gemini training; does not affect Googlebot Search
      { userAgent: 'Google-Extended', disallow: '/' },
    ],
    sitemap: 'https://example.com/sitemap.xml',
    host: 'https://example.com',
  }
}
