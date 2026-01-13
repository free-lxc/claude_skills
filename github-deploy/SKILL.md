---
name: github-deploy
description: Complete GitHub deployment solution for static sites, frontend applications, and Node scripts. Use when deploying to GitHub Pages, setting up CI/CD workflows, configuring custom domains, or deploying serverless Node applications. Supports static site deployment (HTML/CSS/JS), framework builds (React/Vue/Next.js/Nuxt), Node script deployment, GitHub Actions workflow setup, and custom domain with HTTPS configuration.
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
3. **Create GitHub Actions workflow** - See workflows below
4. **Push to trigger deployment** - CI/CD handles the rest

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

```yaml
name: Deploy framework site

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
          # Add build-time environment variables
          VITE_API_URL: ${{ secrets.API_URL }}

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist  # Adjust: React/Vite use dist, Vue uses dist, CRA uses build

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
name: Multi-env Deploy

on:
  push:
    branches:
      - develop    # Staging
      - main       # Production

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

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

      - run: npm run build
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

- **Advanced Actions patterns:** See [ADVANCED_WORKFLOWS.md](references/ADVANCED_WORKFLOWS.md)
- **Framework-specific configs:** See [FRAMEWORK_CONFIGS.md](references/FRAMEWORK_CONFIGS.md)
- **DNS and domain setup:** See [DOMAIN_SETUP.md](references/DOMAIN_SETUP.md)
