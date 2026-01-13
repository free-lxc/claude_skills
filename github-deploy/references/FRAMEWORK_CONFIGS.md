# Framework Configuration Guide

Detailed configuration for deploying specific frameworks to GitHub Pages.

## Package Manager Compatibility

All frameworks support multiple package managers. Use the table below to translate commands:

| Command | npm | yarn | pnpm | bun |
|---------|-----|------|------|-----|
| Install deps | `npm install` | `yarn install` | `pnpm install` | `bun install` |
| Install (CI) | `npm ci` | `yarn install --frozen-lockfile` | `pnpm install --frozen-lockfile` | `bun install --frozen-lockfile` |
| Add package | `npm add <pkg>` | `yarn add <pkg>` | `pnpm add <pkg>` | `bun add <pkg>` |
| Dev server | `npm run dev` | `yarn dev` | `pnpm dev` | `bun run dev` |
| Build | `npm run build` | `yarn build` | `pnpm build` | `bun run build` |
| Test | `npm test` | `yarn test` | `pnpm test` | `bun test` |

For detailed package manager setup, see [PACKAGE_MANAGER_CONFIG.md](PACKAGE_MANAGER_CONFIG.md).

---

## Vite (React, Vue, Vanilla)

### Basic Config

```javascript
// vite.config.js
export default {
  build: {
    outDir: 'dist',
  }
}
```

### Subdirectory Deployment

```javascript
// vite.config.js
export default {
  base: '/repository-name/',
}
```

### Environment Variables

```javascript
// vite.config.js
export default {
  define: {
    'import.meta.env.VITE_API_URL': JSON.stringify(process.env.VITE_API_URL)
  }
}
```

### package.json Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  }
}
```

### CI/CD Command Examples

```yaml
# npm
- run: npm ci
- run: npm run build

# yarn
- run: yarn install --frozen-lockfile
- run: yarn build

# pnpm
- run: pnpm install --frozen-lockfile
- run: pnpm run build

# bun
- run: bun install --frozen-lockfile
- run: bun run build
```

---

## Next.js

### Static Export Config

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  images: {
    unoptimized: true
  },
  trailingSlash: true,
  assetPrefix: '/repository-name',  // For subdirectory
}
```

### Environment Variables

Create `.env.production`:
```
NEXT_PUBLIC_API_URL=https://api.example.com
```

In workflow:
```yaml
- run: npm run build
  env:
    NEXT_PUBLIC_API_URL: ${{ secrets.API_URL }}
```

### package.json Scripts

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "export": "next build"
  }
}
```

### Build Output Directory: `out/`

---

## Nuxt 3

### Nitro Static Config

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  nitro: {
    preset: 'static',
    baseURL: '/repository-name',  // For subdirectory
  }
})
```

### Environment Variables

```bash
# .env.production
NUXT_PUBLIC_API_URL=https://api.example.com
```

### package.json Scripts

```json
{
  "scripts": {
    "dev": "nuxt dev",
    "build": "nuxt build",
    "generate": "nuxt generate"
  }
}
```

### Build Output Directory: `.output/public/`

---

## Vue CLI

### Public Path Config

```javascript
// vue.config.js
module.exports = {
  publicPath: process.env.NODE_ENV === 'production'
    ? '/repository-name/'
    : '/',
  outputDir: 'dist',
}
```

### package.json Scripts

```json
{
  "scripts": {
    "serve": "vue-cli-service serve",
    "build": "vue-cli-service build"
  }
}
```

### Build Output Directory: `dist/`

---

## Create React App

### Homepage Config

```json
// package.json
{
  "homepage": "/repository-name/",
}
```

Or use `.env` file:
```
PUBLIC_URL=/repository-name
```

### package.json Scripts

```json
{
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  }
}
```

### Build Output Directory: `build/`

---

## Angular

### Base Href Config

```json
// angular.json
"build": {
  "options": {
    "baseHref": "/repository-name/",
    "outputPath": "dist/your-project"
  }
}
```

Or command line:
```bash
ng build --base-href /repository-name/
```

### package.json Scripts

```json
{
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build --configuration production"
  }
}
```

### Build Output Directory: `dist/your-project/`

---

## SvelteKit

### Static Adapter Config

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-static';

export default {
  kit: {
    adapter: adapter({
      pages: 'build',
      assets: 'build',
      fallback: 'index.html',
      precompress: false,
      strict: true
    }),
    paths: {
      base: '/repository-name'  // For subdirectory
    }
  }
};
```

### package.json Scripts

```json
{
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "vite preview"
  }
}
```

### Build Output Directory: `build/`

---

## Astro

### Static Build Config

```javascript
// astro.config.mjs
export default defineConfig({
  output: 'static',
  base: '/repository-name',  // For subdirectory
  build: {
    format: 'directory'
  }
});
```

### package.json Scripts

```json
{
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev",
    "build": "astro build",
    "preview": "astro preview"
  }
}
```

### Build Output Directory: `dist/`

---

## Remix

### Static Adapter Config

```javascript
// remix.config.js
export default {
  publicPath: "/build/",
  server: "./server.js",
  appDirectory: "app",
  assetsBuildDirectory: "public/build",
  serverBuildPath: "build/index.js",
  ssr: false,  // Disable SSR for static export
};
```

### package.json Scripts

```json
{
  "scripts": {
    "dev": "remix dev",
    "build": "remix build"
  }
}
```

### Build Output Directory: `public/build/`

---

## Gatsby

### Path Prefix Config

```javascript
// gatsby-config.js
module.exports = {
  pathPrefix: '/repository-name',
}
```

Or environment variable:
```bash
GATSBY_PATH_PREFIX=/repository-name gatsby build
```

### package.json Scripts

```json
{
  "scripts": {
    "develop": "gatsby develop",
    "build": "gatsby build"
  }
}
```

### Build Output Directory: `public/`

---

## Docusaurus

### Deployment Config

```javascript
// docusaurus.config.js
module.exports = {
  url: 'https://username.github.io',
  baseUrl: '/repository-name/',
  organizationName: 'username',
  projectName: 'repository',
  trailingSlash: false,
}
```

### Deployment Command

```bash
npm run deploy
```

Docusaurus includes built-in deployment for GitHub Pages.

### package.json Scripts

```json
{
  "scripts": {
    "start": "docusaurus start",
    "build": "docusaurus build",
    "deploy": "docusaurus deploy"
  }
}
```

### Build Output Directory: `build/`

---

## Build Output Quick Reference

| Framework | Output Directory | Build Command |
|-----------|------------------|---------------|
| Vite | `dist/` | `vite build` |
| React CRA | `build/` | `npm run build` |
| Vue CLI | `dist/` | `vue-cli-service build` |
| Next.js | `out/` | `next build` |
| Nuxt | `.output/public/` | `nuxt generate` |
| Angular | `dist/project-name/` | `ng build` |
| SvelteKit | `build/` | `npm run build` |
| Astro | `dist/` | `astro build` |
| Gatsby | `public/` | `gatsby build` |
| Docusaurus | `build/` | `docusaurus build` |

---

## Common Issues

### 404 on Refresh

**Cause:** Router mode not set to hash/static

**Solution:** Use hash router or configure server redirects

```javascript
// React Router v6 - HashRouter
import { HashRouter } from 'react-router-dom';

<HashRouter>
  <App />
</HashRouter>
```

### Images Not Loading

**Cause:** Absolute paths in subdirectory deployment

**Solution:** Use relative paths or configure base

```javascript
// Vite: use relative imports
import logo from './assets/logo.png';
```

### Environment Variables Undefined

**Cause:** Wrong prefix or not passed to build

**Solution:** Use correct prefix
- Vite: `VITE_`
- Next.js: `NEXT_PUBLIC_`
- Nuxt: `NUXT_PUBLIC_`
