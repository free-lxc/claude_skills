# Package Manager Configuration Guide

Complete guide for configuring different package managers in GitHub Actions workflows.

## Table of Contents

1. [Quick Detection](#quick-detection)
2. [npm](#npm)
3. [yarn](#yarn)
4. [pnpm](#pnpm)
5. [bun](#bun)
6. [Migration Guide](#migration-guide)
7. [Best Practices](#best-practices)

---

## Quick Detection

### Detect from Lock Files

| Lock File | Package Manager | Detection Command |
|-----------|-----------------|-------------------|
| `package-lock.json` | npm | `ls package-lock.json` |
| `yarn.lock` | yarn | `ls yarn.lock` |
| `pnpm-lock.yaml` | pnpm | `ls pnpm-lock.yaml` |
| `bun.lockb` | bun | `ls bun.lockb` |

### Detect from package.json

```bash
# Check packageManager field
cat package.json | grep '"packageManager"'
```

Output examples:
```json
"packageManager": "npm@10.2.4"
"packageManager": "yarn@1.22.19"
"packageManager": "yarn@4.0.2"
"packageManager": "pnpm@9.0.0"
"packageManager": "bun@1.0.0"
```

### Auto-Detection Script

Add to your workflow:

```yaml
- name: Detect package manager
  id: detect-pm
  run: |
    if [ -f "package-lock.json" ]; then
      echo "manager=npm" >> $GITHUB_OUTPUT
    elif [ -f "pnpm-lock.yaml" ]; then
      echo "manager=pnpm" >> $GITHUB_OUTPUT
    elif [ -f "bun.lockb" ]; then
      echo "manager=bun" >> $GITHUB_OUTPUT
    else
      echo "manager=yarn" >> $GITHUB_OUTPUT
    fi
```

---

## npm

npm is the default package manager for Node.js.

### Setup

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'

- name: Install dependencies
  run: npm ci

- name: Build
  run: npm run build

- name: Test
  run: npm test
```

### Cache Configuration

```yaml
# Automatic caching (recommended)
- uses: actions/setup-node@v4
  with:
    cache: 'npm'

# Manual caching (advanced)
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

### Common Commands

| Command | Description |
|---------|-------------|
| `npm ci` | Clean install (CI) |
| `npm install` | Install dependencies |
| `npm run build` | Run build script |
| `npm run <script>` | Run custom script |

### package.json Example

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "packageManager": "npm@10.2.4",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "vitest"
  }
}
```

---

## yarn

yarn is a fast, reliable, and secure dependency manager.

### yarn v1 (Classic)

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'yarn'

- name: Install dependencies
  run: yarn install --frozen-lockfile

- name: Build
  run: yarn build
```

### yarn v3+ (Berry)

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'yarn'

- name: Enable Corepack
  run: |
    corepack enable
    yarn set version stable

- name: Install dependencies
  run: yarn install --immutable

- name: Build
  run: yarn build
```

### Detect yarn Version

```bash
# Check for yarn berry indicators
if [ -f ".yarnrc.yml" ] || [ -d ".yarn/cache" ]; then
  echo "yarn berry detected"
else
  echo "yarn v1 detected"
fi
```

### Cache Configuration

```yaml
# yarn v1
- uses: actions/setup-node@v4
  with:
    cache: 'yarn'  # Caches node_modules/.cache/yarn

# yarn berry
- uses: actions/cache@v4
  with:
    path: |
      .yarn/cache
      .yarn/install-state.gz
    key: ${{ runner.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
```

### Common Commands

| Command | yarn v1 | yarn v3+ |
|---------|---------|----------|
| Install | `yarn install --frozen-lockfile` | `yarn install --immutable` |
| Add | `yarn add <pkg>` | `yarn add <pkg>` |
| Remove | `yarn remove <pkg>` | `yarn remove <pkg>` |
| Build | `yarn build` | `yarn build` |
| Run | `yarn <script>` | `yarn <script>` |

### .yarnrc.yml Example (yarn berry)

```yaml
nodeLinker: node-modules
enableGlobalCache: true
```

---

## pnpm

pnpm uses hard links and symbolic links to save disk space.

### Setup

```yaml
- name: Setup pnpm
  uses: pnpm/action-setup@v4
  with:
    version: 9

- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'pnpm'

- name: Install dependencies
  run: pnpm install --frozen-lockfile

- name: Build
  run: pnpm run build
```

### Cache Configuration

```yaml
# Automatic caching (recommended)
- uses: pnpm/action-setup@v4
  with:
    version: 9
- uses: actions/setup-node@v4
  with:
    cache: 'pnpm'  # Caches node_modules/.cache/pnpm

# Manual caching (advanced)
- uses: actions/cache@v4
  with:
    path: |
      ~/.pnpm-store
      node_modules/.cache/pnpm
    key: ${{ runner.os }}-pnpm-${{ hashFiles('**/pnpm-lock.yaml') }}
```

### Common Commands

| Command | Description |
|---------|-------------|
| `pnpm install --frozen-lockfile` | Install dependencies (CI) |
| `pnpm add <pkg>` | Add dependency |
| `pnpm remove <pkg>` | Remove dependency |
| `pnpm run build` | Run build script |
| `pnpm <script>` | Run custom script |

### package.json Example

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "packageManager": "pnpm@9.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  }
}
```

### pnpm-workspace.yaml (Monorepo)

```yaml
packages:
  - 'packages/*'
  - 'apps/*'
```

---

## bun

Bun is a fast JavaScript runtime, package manager, bundler, and test runner.

### Setup

```yaml
- name: Setup bun
  uses: oven-sh/setup-bun@v2
  with:
    bun-version: latest

- name: Install dependencies
  run: bun install --frozen-lockfile

- name: Build
  run: bun run build

- name: Test
  run: bun test
```

### Cache Configuration

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.bun/install/cache
      node_modules/.cache/bun
    key: ${{ runner.os }}-bun-${{ hashFiles('**/bun.lockb') }}
```

### Common Commands

| Command | Description |
|---------|-------------|
| `bun install` | Install dependencies |
| `bun install --frozen-lockfile` | Install dependencies (CI) |
| `bun add <pkg>` | Add dependency |
| `bun remove <pkg>` | Remove dependency |
| `bun run build` | Run build script |
| `bun <script>` | Run custom script |
| `bun test` | Run tests |

### package.json Example

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "packageManager": "bun@1.0.0",
  "scripts": {
    "dev": "bun run src/index.ts",
    "build": "bun build src/index.ts --outdir ./dist",
    "start": "bun run dist/index.js",
    "test": "bun test"
  }
}
```

---

## Migration Guide

### npm to yarn

```bash
# Install yarn
npm install -g yarn

# Migrate (yarn v1)
yarn import

# Or start fresh
rm package-lock.json
yarn install
```

### npm to pnpm

```bash
# Install pnpm
npm install -g pnpm

# Migrate
pnpm import

# Install dependencies
pnpm install
```

### npm to bun

```bash
# Install bun
curl -fsSL https://bun.sh/install | bash

# Migrate (bun converts package-lock)
bun install
```

### yarn to pnpm

```bash
# Convert lock file
pnpm import

# Install dependencies
pnpm install
```

---

## Best Practices

### 1. Use packageManager Field

Always specify the package manager in package.json:

```json
{
  "packageManager": "pnpm@9.0.0"
}
```

This enables Corepack to automatically use the correct version:

```yaml
- run: corepack enable
- run: pnpm install  # Uses version 9.0.0
```

### 2. Use Frozen Lockfiles in CI

Always use frozen lockfile commands in CI:

| Package Manager | Command |
|----------------|---------|
| npm | `npm ci` |
| yarn v1 | `yarn install --frozen-lockfile` |
| yarn v3+ | `yarn install --immutable` |
| pnpm | `pnpm install --frozen-lockfile` |
| bun | `bun install --frozen-lockfile` |

### 3. Cache Dependencies

Always cache dependencies for faster builds:

```yaml
- uses: actions/setup-node@v4
  with:
    cache: 'npm'  # or 'yarn', 'pnpm'
```

### 4. Consistent Node.js Version

Pin Node.js version in workflows:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'  # Or '20.x' for latest 20.x.x
```

### 5. Use .npmrc for Private Registries

Create `.npmrc` in project root:

```ini
@scope:registry=https://npm.pkg.github.com/owner
//npm.pkg.github.com/owner:_authToken=${NPM_TOKEN}
```

Add token to repository secrets:

```yaml
- name: Install dependencies
  run: pnpm install
  env:
    NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### 6. Monorepo Considerations

For monorepos, use workspace-specific commands:

```yaml
# pnpm workspace
- run: pnpm install --frozen-lockfile
- run: pnpm -r --filter=my-app build

# yarn workspace
- run: yarn install --frozen-lockfile
- run: yarn workspace my-app build
```

---

## Quick Reference Matrix

| Feature | npm | yarn v1 | yarn v3+ | pnpm | bun |
|---------|-----|---------|----------|------|-----|
| Lock File | `package-lock.json` | `yarn.lock` | `yarn.lock` | `pnpm-lock.yaml` | `bun.lockb` |
| CI Install | `npm ci` | `yarn install --frozen-lockfile` | `yarn install --immutable` | `pnpm install --frozen-lockfile` | `bun install --frozen-lockfile` |
| Cache Key | `npm` | `yarn` | `yarn` | `pnpm` | `bun` |
| GitHub Action | `actions/setup-node@v4` | `actions/setup-node@v4` | `actions/setup-node@v4` | `pnpm/action-setup@v4` | `oven-sh/setup-bun@v2` |
| Cache Path | `~/.npm` | `node_modules/.cache/yarn` | `.yarn/cache` | `node_modules/.cache/pnpm` | `~/.bun/install/cache` |
| Workspace Support | Yes (workspaces) | Yes (workspaces) | Yes (workspaces) | Yes (workspaces) | Yes (workspaces) |

---

## Troubleshooting

### Cache Not Working

Ensure the lock file exists and is committed:

```bash
git add package-lock.json  # or yarn.lock, pnpm-lock.yaml, bun.lockb
git commit -m "Add lock file"
```

### Package Manager Not Found

Enable Corepack for yarn/pnpm:

```yaml
- run: corepack enable
```

### Frozen Lockfile Fails

Lock file mismatch detected. Run:

```bash
# npm
rm package-lock.json && npm install

# yarn
rm yarn.lock && yarn install

# pnpm
rm pnpm-lock.yaml && pnpm install

# bun
rm bun.lockb && bun install
```

### Monorepo Build Issues

Use filtered commands:

```yaml
# pnpm
- run: pnpm -r --filter=my-app build

# yarn
- run: yarn workspace my-app build

# npm
- run: npm run build --workspace=my-app
```
