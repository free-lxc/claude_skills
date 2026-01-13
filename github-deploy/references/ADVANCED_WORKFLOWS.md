# Advanced GitHub Actions Workflows

Complex deployment patterns and CI/CD workflows for GitHub Pages.

## Table of Contents

1. [Matrix Builds](#matrix-builds)
2. [Conditional Deployments](#conditional-deployments)
3. [Monorepo Deployments](#monorepo-deployments)
4. [Build Caching](#build-caching)
5. [Parallel Jobs](#parallel-jobs)
6. [Deployment Notifications](#deployment-notifications)
7. [Rollback Strategies](#rollback-strategies)
8. [Scheduled Deployments](#scheduled-deployments)

---

## Matrix Builds

Test across multiple Node versions and platforms:

```yaml
name: Matrix Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        node: [18, 20, 22]
        os: [ubuntu-latest, windows-latest, macos-latest]
      fail-fast: false

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: 'npm'

      - run: npm ci
      - run: npm test
```

---

## Conditional Deployments

Deploy based on file changes or commit messages:

### Deploy on Specific Paths Changed

```yaml
name: Conditional Deploy

on:
  push:
    branches: [main]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      frontend-changed: ${{ steps.changes.outputs.frontend }}
      docs-changed: ${{ steps.changes.outputs.docs }}

    steps:
      - uses: actions/checkout@v4

      - uses: dorny/paths-filter@v3
        id: changes
        with:
          filters: |
            frontend:
              - 'src/**'
              - 'package.json'
            docs:
              - 'docs/**'

  deploy-frontend:
    needs: detect-changes
    if: needs.detect-changes.outputs.frontend-changed == 'true'
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - # Deploy steps...

  deploy-docs:
    needs: detect-changes
    if: needs.detect-changes.outputs.docs-changed == 'true'
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - # Deploy steps...
```

### Deploy Based on Commit Message

```yaml
name: Message-Based Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: contains(github.event.head_commit.message, '[deploy]')

    steps:
      - uses: actions/checkout@v4
      - # Deploy steps...
```

### Skip Deploy with Comment

```yaml
name: Skip Deploy

on:
  push:
    branches: [main]

jobs:
  check-skip:
    runs-on: ubuntu-latest
    outputs:
      should-skip: ${{ steps.check.outputs.skip }}

    steps:
      - uses: actions/checkout@v4

      - id: check
        run: |
          if [[ "${{ github.event.head_commit.message }}" == *"[skip deploy]"* ]]; then
            echo "skip=true" >> $GITHUB_OUTPUT
          else
            echo "skip=false" >> $GITHUB_OUTPUT
          fi

  deploy:
    needs: check-skip
    if: needs.check-skip.outputs.should-skip == 'false'
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - # Deploy steps...
```

---

## Monorepo Deployments

Deploy multiple packages from a single repository:

```yaml
name: Monorepo Deploy

on:
  push:
    branches: [main]

jobs:
  detect-packages:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.detect.outputs.packages }}

    steps:
      - uses: actions/checkout@v4

      - id: detect
        run: |
          PACKAGES=$(ls -d packages/* | jq -R -s -c 'split("\n")[:-1]')
          echo "packages=$PACKAGES" >> $GITHUB_OUTPUT

  deploy-packages:
    needs: detect-packages
    runs-on: ubuntu-latest
    strategy:
      matrix:
        package: ${{ fromJson(needs.detect-packages.outputs.packages) }}
      fail-fast: false

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - working-directory: ${{ matrix.package }}
        run: |
          npm ci
          npm run build

      - # Deploy specific package
```

### Nx/Turborepo Monorepo

```yaml
name: Nx Monorepo Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # For nx affected

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci

      - name: Derive affected
        id: affected
        run: |
          AFFECTED=$(npx nx show projects --affected --json)
          echo "projects=$AFFECTED" >> $GITHUB_OUTPUT

      - name: Deploy affected apps
        if: contains(steps.affected.outputs.projects, 'frontend')
        run: |
          npx nx run frontend:deploy
```

---

## Build Caching

Speed up builds with dependency and build caching:

```yaml
name: Cached Build

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'  # Auto-caches node_modules

      - name: Cache build output
        uses: actions/cache@v4
        with:
          path: |
            dist
            .next/cache
          key: ${{ runner.os }}-build-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-build-

      - run: npm ci
      - run: npm run build
```

### Custom Cache Strategy

```yaml
- name: Cache node_modules
  uses: actions/cache@v4
  id: cache-npm
  with:
    path: node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}

- name: Install if cache miss
  if: steps.cache-npm.outputs.cache-hit != 'true'
  run: npm ci
```

---

## Parallel Jobs

Run tests, linting, and build in parallel:

```yaml
name: Parallel Deploy

on:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm test

  build:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run build

  deploy:
    runs-on: ubuntu-latest
    needs: [build]
    permissions:
      pages: write
      id-token: write
    steps:
      - uses: actions/deploy-pages@v4
```

---

## Deployment Notifications

Send notifications on deployment status:

```yaml
name: Notify on Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - # Deploy steps...

      - name: Notify Slack on success
        if: success()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment successful!",
              "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}

      - name: Notify Slack on failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment failed!",
              "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Discord Notification

```yaml
- name: Notify Discord
  if: always()
  uses: sarisia/actions-status-discord@v1
  with:
    webhook: ${{ secrets.DISCORD_WEBHOOK }}
    status: ${{ job.status }}
    title: "Deployment ${{ job.status }}"
```

---

## Rollback Strategies

### Manual Rollback Workflow

```yaml
name: Rollback Deployment

on:
  workflow_dispatch:
    inputs:
      sha:
        description: 'Commit SHA to rollback to'
        required: true

jobs:
  rollback:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pages: write
      id-token: write

    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ inputs.sha }}

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci
      - run: npm run build

      - uses: actions/configure-pages@v5

      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - uses: actions/deploy-pages@v4
```

### Automatic Rollback on Failure

```yaml
name: Deploy with Auto-Rollback

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Get previous SHA
        id: prev-sha
        run: |
          PREV_SHA=$(git log --pretty=format:'%H' -2 | tail -n 1)
          echo "sha=$PREV_SHA" >> $GITHUB_OUTPUT

      - uses: actions/setup-node@v4

      - run: npm ci
      - run: npm run build

      - uses: actions/configure-pages@v5

      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - uses: actions/deploy-pages@v4

      - name: Health check
        run: |
          sleep 30  # Wait for deployment
          curl -f https://example.com || exit 1

      - name: Rollback on failure
        if: failure()
        run: |
          gh workflow run rollback.yml -f sha=${{ steps.prev-sha.outputs.sha }}
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Scheduled Deployments

Run builds on a schedule:

```yaml
name: Scheduled Deploy

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Fetch latest data
        run: npm run fetch-data  # Update dynamic content

      - uses: actions/setup-node@v4

      - run: npm ci
      - run: npm run build

      - uses: actions/configure-pages@v5

      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - uses: actions/deploy-pages@v4
```

---

## Reusable Workflows

Create reusable deployment workflows:

### `.github/workflows/reusable-deploy.yml`

```yaml
name: Reusable Deploy

on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
      build-command:
        required: true
        type: string
      output-dir:
        required: true
        type: string

    secrets:
      API_TOKEN:
        required: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pages: write
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}

      - run: npm ci

      - run: ${{ inputs.build-command }}
        env:
          API_TOKEN: ${{ secrets.API_TOKEN }}

      - uses: actions/configure-pages@v5

      - uses: actions/upload-pages-artifact@v3
        with:
          path: ${{ inputs.output-dir }}

      - uses: actions/deploy-pages@v4
```

### Usage in other repos

```yaml
name: Deploy Using Reusable

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: org/repo/.github/workflows/reusable-deploy.yml@main
    with:
      node-version: '20'
      build-command: 'npm run build'
      output-dir: './dist'
    secrets:
      API_TOKEN: ${{ secrets.API_TOKEN }}
```

---

## Build Artifacts

Upload and download artifacts between jobs:

```yaml
name: Artifact Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4

      - run: npm ci
      - run: npm run build

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: ./dist
          retention-days: 7

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest

    steps:
      - name: Download build artifact
        uses: actions/download-artifact@v4
        with:
          name: build-output
          path: ./dist

      - # Deploy to staging...

  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Download build artifact
        uses: actions/download-artifact@v4
        with:
          name: build-output
          path: ./dist

      - # Deploy to production...
```

---

## Environment-Specific Configs

```yaml
name: Multi-Env Deploy

on:
  push:
    branches: [develop, main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set environment variables
        run: |
          if [[ "${{ github.ref_name }}" == "main" ]]; then
            echo "ENV=production" >> $GITHUB_ENV
            echo "API_URL=${{ secrets.PROD_API_URL }}" >> $GITHUB_ENV
          else
            echo "ENV=staging" >> $GITHUB_ENV
            echo "API_URL=${{ secrets.STAGING_API_URL }}" >> $GITHUB_ENV
          fi

      - uses: actions/setup-node@v4

      - run: npm ci

      - run: npm run build
        env:
          VITE_API_URL: ${{ env.API_URL }}

      - uses: actions/configure-pages@v5

      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

      - uses: actions/deploy-pages@v4
```

---

## Manual Approval

Require approval before production deployment:

```yaml
name: Deploy with Approval

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com

    steps:
      - uses: actions/checkout@v4
      - # Deploy steps...
```

Configure in repository Settings > Environments:

1. Create "production" environment
2. Add required reviewers
3. Set wait timer
4. Add protection rules
