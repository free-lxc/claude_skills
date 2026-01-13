---
name: github-deploy
description: Complete GitHub deployment solution with automatic package manager detection. Automatically detects npm/yarn/pnpm/bun and generates matching CI/CD workflows. Use when deploying to GitHub Pages, setting up CI/CD workflows, configuring custom domains, or deploying serverless Node applications. Supports static sites (HTML/CSS/JS), framework builds (React/Vue/Next.js/Nuxt/Angular), Node script deployment, multi-environment deployments, and custom domain with HTTPS configuration.
---

# GitHub Deploy

Automated deployment workflows for GitHub Pages and Node applications.

## Deployment Decision Tree

```
Project Type?
├── Static Site (HTML/CSS/JS)
│   └── Use: Static Pages Workflow
├── Frontend Framework (React/Vue/Angular)
│   ├── Needs Build Step?
│   │   ├── Yes: Framework Build Workflow
│   │   └── No: Static Pages Workflow
├── Full Stack Framework (Next.js/Nuxt/Astro)
│   └── Use: Static Export Workflow
├── Node Script/App
│   └── Use: Node Deployment Workflow
└── Custom Domain Needed?
    └── Add: Domain Configuration Step
```

## Quick Start

For any deployment:

1. **Check GitHub repository exists** - Initialize if needed
2. **Identify project type** - Use decision tree above
3. **Detect package manager** - See section below
4. **Create GitHub Actions workflow** - See workflows below
5. **Push to trigger deployment** - CI/CD handles the rest

---

## Package Manager Detection

GitHub Actions workflows need to use the correct package manager and cache configuration.

### Detection Methods

**Method 1: Check lock file**
```bash
# In your project directory
ls -la | grep -E "(package-lock|yarn.lock|pnpm-lock|bun.lock)"
```

| Lock File | Package Manager |
|-----------|-----------------|
| `package-lock.json` | npm |
| `yarn.lock` | yarn (classic) |
| `yarn.lock` + `.yarn/cache` | yarn (berry/v3+) |
| `pnpm-lock.yaml` | pnpm |
| `bun.lockb` | bun |
| `node_modules` only | Check package.json `packageManager` field |

**Method 2: Check package.json**
```bash
# Look for packageManager field
cat package.json | grep "packageManager"
```

Examples:
```json
{
  "packageManager": "npm@10.2.4"
  "packageManager": "yarn@1.22.19"
  "packageManager": "yarn@4.0.2"
  "packageManager": "pnpm@9.0.0"
  "packageManager": "bun@1.0.0"
}
```

**Method 3: Check CLI availability**
```bash
which npm && echo "npm available"
which yarn && echo "yarn available"
which pnpm && echo "pnpm available"
which bun && echo "bun available"
```

### Quick Reference Matrix

| Package Manager | Install Command | Cache Key | Cache Path |
|----------------|-----------------|-----------|------------|
| npm | `npm ci` | `npm` | `node_modules` |
| yarn v1 | `yarn install --frozen-lockfile` | `yarn` | `node_modules/.cache/yarn` |
| yarn v3+ | `yarn install --immutable` | `yarn` | `.yarn/cache` |
| pnpm | `pnpm install --frozen-lockfile` | `pnpm` | `node_modules/.cache/pnpm` |
| bun | `bun install --frozen-lockfile` | `bun` | `node_modules/.cache/bun` |

### Package Manager Actions Setup

```yaml
# npm
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'

# yarn (v1)
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'yarn'

# yarn (berry/v3+)
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'yarn'
- run: corepack enable
- run: yarn set version stable
- run: yarn install --immutable

# pnpm
- uses: pnpm/action-setup@v4
  with:
    version: 9
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'pnpm'
- run: pnpm install --frozen-lockfile

# bun
- uses: oven-sh/setup-bun@v2
  with:
    bun-version: latest
- run: bun install --frozen-lockfile
```

### Unified Workflow Template (All Package Managers)

```yaml
name: Deploy with Package Manager Detection

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Detect and setup package manager
      - name: Detect package manager
        id: detect-pm
        run: |
          if [ -f "package-lock.json" ]; then
            echo "manager=npm" >> $GITHUB_OUTPUT
            echo "cache=npm" >> $GITHUB_OUTPUT
            echo "command=npm ci" >> $GITHUB_OUTPUT
            echo "build=npm run build" >> $GITHUB_OUTPUT
          elif [ -f "pnpm-lock.yaml" ]; then
            echo "manager=pnpm" >> $GITHUB_OUTPUT
            echo "cache=pnpm" >> $GITHUB_OUTPUT
            echo "command=pnpm install --frozen-lockfile" >> $GITHUB_OUTPUT
            echo "build=pnpm run build" >> $GITHUB_OUTPUT
          elif [ -f "bun.lockb" ]; then
            echo "manager=bun" >> $GITHUB_OUTPUT
            echo "cache=bun" >> $GITHUB_OUTPUT
            echo "command=bun install --frozen-lockfile" >> $GITHUB_OUTPUT
            echo "build=bun run build" >> $GITHUB_OUTPUT
          else
            echo "manager=yarn" >> $GITHUB_OUTPUT
            echo "cache=yarn" >> $GITHUB_OUTPUT
            echo "command=yarn install --frozen-lockfile" >> $GITHUB_OUTPUT
            echo "build=yarn build" >> $GITHUB_OUTPUT
          fi

      # Setup Node.js with detected cache
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: ${{ steps.detect-pm.outputs.cache }}

      # Special setup for pnpm
      - name: Setup pnpm
        if: steps.detect-pm.outputs.manager == 'pnpm'
        uses: pnpm/action-setup@v4
        with:
          version: 9

      # Special setup for bun
      - name: Setup bun
        if: steps.detect-pm.outputs.manager == 'bun'
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest

      # Special setup for yarn berry
      - name: Enable Corepack (yarn berry)
        if: steps.detect-pm.outputs.manager == 'yarn'
        run: |
          corepack enable
          if grep -q '"yarn"' .yarnrc.yml 2>/dev/null || [ -d ".yarn/cache" ]; then
            yarn set version stable
          fi

      # Install dependencies
      - name: Install dependencies
        run: ${{ steps.detect-pm.outputs.command }}

      # Build project
      - name: Build
        run: ${{ steps.detect-pm.outputs.build }}

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - name: Deploy to Pages
        uses: actions/deploy-pages@v4
```

---

## Workflows

### Static Pages Workflow

Use for: Pure HTML/CSS/JS, no build step required.

**Workflow file:** `.github/workflows/deploy.yml`

```yaml
name: Deploy static site to Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'

      - name: Deploy to Pages
        uses: actions/deploy-pages@v4
```

**Settings:** In repo Settings > Pages, set source to "GitHub Actions"

---

### Framework Build Workflow

Use for: React, Vue, Angular - any framework requiring build step.

**Workflow file:** `.github/workflows/deploy.yml`

#### Option A: Automatic Detection (Recommended)

Use the unified workflow template from the **Package Manager Detection** section above. It automatically detects and configures npm, yarn, pnpm, or bun.

#### Option B: npm

```yaml
name: Deploy framework site (npm)

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
        env:
          VITE_API_URL: ${{ secrets.API_URL }}

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - name: Deploy to Pages
        uses: actions/deploy-pages@v4
```

#### Option C: yarn

```yaml
name: Deploy framework site (yarn)

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'yarn'

      - name: Enable Corepack (yarn berry)
        run: |
          corepack enable
          if [ -f ".yarnrc.yml" ]; then
            yarn set version stable
          fi

      - name: Install dependencies
        run: yarn install --frozen-lockfile

      - name: Build
        run: yarn build
        env:
          VITE_API_URL: ${{ secrets.API_URL }}

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - name: Deploy to Pages
        uses: actions/deploy-pages@v4
```

#### Option D: pnpm

```yaml
name: Deploy framework site (pnpm)

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build
        run: pnpm run build
        env:
          VITE_API_URL: ${{ secrets.API_URL }}

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - name: Deploy to Pages
        uses: actions/deploy-pages@v4
```

#### Option E: bun

```yaml
name: Deploy framework site (bun)

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest

      - name: Install dependencies
        run: bun install --frozen-lockfile

      - name: Build
        run: bun run build
        env:
          VITE_API_URL: ${{ secrets.API_URL }}

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - name: Deploy to Pages
        uses: actions/deploy-pages@v4
```

**Build output directories:**
- Vite/React: `dist/`
- Vue CLI: `dist/`
- Create React App: `build/`
- Next.js static: `out/`

---

### Node Script Deployment

Use for: Deploying Node scripts, CLI tools, serverless functions.

**Option A: Deploy as NPM Package**

**Workflow file:** `.github/workflows/publish.yml`

```yaml
name: Publish to NPM

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'

      - run: npm ci

      - run: npm publish --provenance
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Required in `package.json`:**
```json
{
  "name": "your-package-name",
  "version": "1.0.0",
  "bin": {
    "your-command": "./dist/cli.js"
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsc",
    "prepare": "npm run build"
  }
}
```

**Option B: Deploy as GitHub Release**

**Workflow file:** `.github/workflows/release.yml`

```yaml
name: Create Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci
      - run: npm run build

      - uses: softprops/action-gh-release@v2
        with:
          files: |
            dist/*.js
            dist/*.js.map
            README.md
            package.json
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### Multi-Environment Workflow

Use for: Separate staging/production deployments.

**Workflow file:** `.github/workflows/deploy.yml`

```yaml
name: Multi-env Deploy with Package Manager Detection

on:
  push:
    branches:
      - develop    # Staging
      - main       # Production

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Detect package manager
      - name: Detect package manager
        id: detect-pm
        run: |
          if [ -f "package-lock.json" ]; then
            echo "manager=npm" >> $GITHUB_OUTPUT
            echo "cache=npm" >> $GITHUB_OUTPUT
            echo "install=npm ci" >> $GITHUB_OUTPUT
            echo "build=npm run build" >> $GITHUB_OUTPUT
          elif [ -f "pnpm-lock.yaml" ]; then
            echo "manager=pnpm" >> $GITHUB_OUTPUT
            echo "cache=pnpm" >> $GITHUB_OUTPUT
            echo "install=pnpm install --frozen-lockfile" >> $GITHUB_OUTPUT
            echo "build=pnpm run build" >> $GITHUB_OUTPUT
          elif [ -f "bun.lockb" ]; then
            echo "manager=bun" >> $GITHUB_OUTPUT
            echo "cache=bun" >> $GITHUB_OUTPUT
            echo "install=bun install --frozen-lockfile" >> $GITHUB_OUTPUT
            echo "build=bun run build" >> $GITHUB_OUTPUT
          else
            echo "manager=yarn" >> $GITHUB_OUTPUT
            echo "cache=yarn" >> $GITHUB_OUTPUT
            echo "install=yarn install --frozen-lockfile" >> $GITHUB_OUTPUT
            echo "build=yarn build" >> $GITHUB_OUTPUT
          fi

      # Setup based on package manager
      - name: Setup pnpm
        if: steps.detect-pm.outputs.manager == 'pnpm'
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Setup bun
        if: steps.detect-pm.outputs.manager == 'bun'
        uses: oven-sh/setup-bun@v2

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: ${{ steps.detect-pm.outputs.cache }}

      - name: Enable Corepack (yarn)
        if: steps.detect-pm.outputs.manager == 'yarn'
        run: corepack enable

      # Environment-specific configs
      - name: Configure for ${{ github.ref_name }}
        run: |
          if [ "${{ github.ref_name }}" = "main" ]; then
            echo "DEPLOY_ENV=production" >> $GITHUB_ENV
            echo "VITE_API_URL=${{ secrets.PROD_API_URL }}" >> $GITHUB_ENV
          else
            echo "DEPLOY_ENV=staging" >> $GITHUB_ENV
            echo "VITE_API_URL=${{ secrets.STAGING_API_URL }}" >> $GITHUB_ENV
          fi

      - name: Install dependencies
        run: ${{ steps.detect-pm.outputs.install }}

      - name: Build
        run: ${{ steps.detect-pm.outputs.build }}
        env:
          VITE_API_URL: ${{ env.VITE_API_URL }}

      - uses: actions/configure-pages@v5

      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - uses: actions/deploy-pages@v4
```

**Branch protection:** Require PR reviews for main branch

---

## Domain Configuration

### Custom Domain Setup

1. **Configure DNS:**
   - `CNAME record` pointing to `[username].github.io`
   - For apex domain: use `A records` to GitHub IPs

2. **Add CNAME file:**
   - Create `CNAME` in repo root
   - Content: `yourdomain.com`

3. **Enable in GitHub:**
   - Settings > Pages > Custom domain
   - Enforce HTTPS (wait for DNS propagation)

### GitHub IPs for Apex Domains

```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

---

## Project Setup Checklist

### Before First Deployment

- [ ] Repository initialized on GitHub
- [ ] GitHub Actions enabled in repo settings
- [ ] Source branch created (main/develop)
- [ ] `package.json` configured with build scripts
- [ ] Environment variables added to secrets
- [ ] Build output directory identified
- [ ] Static site config (base path) if in subdirectory

### Package.json Requirements

**Minimum for framework builds:**
```json
{
  "scripts": {
    "build": "vite build",
    "preview": "vite preview"
  }
}
```

**For subdirectory deployment (Vite):**
```javascript
// vite.config.js
export default {
  base: '/repo-name/',
}
```

---

## Troubleshooting

### Common Issues

**Build fails in CI but works locally:**
- Check Node version matches in workflow
- Ensure all dependencies in `package.json`
- Verify build environment variables are set

**Deploy succeeds but 404 on pages:**
- Check Pages source is set to "GitHub Actions"
- Verify workflow completed successfully
- Wait up to 5 minutes for propagation

**Static assets not loading:**
- Check `base` path in framework config
- Verify asset paths are relative
- Check case sensitivity in file names

**Environment variables undefined:**
- Ensure secrets added in repo Settings
- Check variable names match exactly
- Use correct syntax: `${{ secrets.VAR_NAME }}`

---

## Scripts

Use `scripts/validate_setup.sh` to verify deployment readiness:

```bash
scripts/validate_setup.sh /path/to/project
```

This checks:
- Git repository status
- package.json configuration
- Build script presence
- Required directories

---

## Reference Guides

For detailed information on specific scenarios:

- **Package manager configuration:** See [PACKAGE_MANAGER_CONFIG.md](references/PACKAGE_MANAGER_CONFIG.md)
- **Advanced Actions patterns:** See [ADVANCED_WORKFLOWS.md](references/ADVANCED_WORKFLOWS.md)
- **Framework-specific configs:** See [FRAMEWORK_CONFIGS.md](references/FRAMEWORK_CONFIGS.md)
- **DNS and domain setup:** See [DOMAIN_SETUP.md](references/DOMAIN_SETUP.md)
