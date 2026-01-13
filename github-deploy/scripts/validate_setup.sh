#!/bin/bash
# validate_setup.sh - Verify project is ready for GitHub deployment
# Usage: scripts/validate_setup.sh /path/to/project

set -e

PROJECT_PATH="${1:-.}"
ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating deployment setup for: $PROJECT_PATH"
echo ""

# Check if directory exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}✗ Error: Directory '$PROJECT_PATH' does not exist${NC}"
    exit 1
fi

cd "$PROJECT_PATH"

# Check Git repository
echo "📦 Checking Git repository..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Git repository initialized${NC}"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "no commits")
    echo "  Current branch: $BRANCH"
else
    echo -e "${RED}✗ Not a Git repository${NC}"
    echo "  Run: git init"
    ERRORS=$((ERRORS + 1))
fi

# Check package.json
echo ""
echo "📋 Checking package.json..."
if [ -f "package.json" ]; then
    echo -e "${GREEN}✓ package.json exists${NC}"

    # Check for build script
    if command -v jq >/dev/null 2>&1; then
        BUILD_SCRIPT=$(jq -r '.scripts.build // empty' package.json 2>/dev/null)
        if [ -n "$BUILD_SCRIPT" ]; then
            echo -e "${GREEN}✓ Build script found: $BUILD_SCRIPT${NC}"
        else
            echo -e "${YELLOW}⚠ No build script in package.json${NC}"
            echo "  Required for framework projects"
            WARNINGS=$((WARNINGS + 1))
        fi

        # Check for packageManager field
        PACKAGE_MANAGER=$(jq -r '.packageManager // empty' package.json 2>/dev/null)
        if [ -n "$PACKAGE_MANAGER" ]; then
            echo -e "${GREEN}✓ packageManager field: $PACKAGE_MANAGER${NC}"
        fi

        # Check for required fields
        NAME=$(jq -r '.name // empty' package.json 2>/dev/null)
        VERSION=$(jq -r '.version // empty' package.json 2>/dev/null)
        echo "  Package name: $NAME"
        echo "  Version: $VERSION"
    fi
else
    echo -e "${YELLOW}⚠ No package.json found${NC}"
    echo "  Static sites may not need this"
    WARNINGS=$((WARNINGS + 1))
fi

# Detect package manager
echo ""
echo "📦 Detecting package manager..."
PACKAGE_MANAGER=""
LOCK_FILE=""

if [ -f "package-lock.json" ]; then
    PACKAGE_MANAGER="npm"
    LOCK_FILE="package-lock.json"
    echo -e "${GREEN}✓ npm detected (package-lock.json found)${NC}"
elif [ -f "pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
    LOCK_FILE="pnpm-lock.yaml"
    echo -e "${GREEN}✓ pnpm detected (pnpm-lock.yaml found)${NC}"
elif [ -f "bun.lockb" ]; then
    PACKAGE_MANAGER="bun"
    LOCK_FILE="bun.lockb"
    echo -e "${GREEN}✓ bun detected (bun.lockb found)${NC}"
elif [ -f "yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
    LOCK_FILE="yarn.lock"
    # Check if it's yarn berry
    if [ -d ".yarn/cache" ] || [ -f ".yarnrc.yml" ]; then
        echo -e "${GREEN}✓ yarn berry detected (yarn.lock + .yarn/cache)${NC}"
        echo "  Use 'corepack enable' in CI/CD"
    else
        echo -e "${GREEN}✓ yarn v1 detected (yarn.lock found)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No lock file found${NC}"
    echo "  Run: npm install / yarn install / pnpm install"
    WARNINGS=$((WARNINGS + 1))
fi

# Display package manager specific info
if [ -n "$PACKAGE_MANAGER" ]; then
    echo "  Package manager: $PACKAGE_MANAGER"
    case "$PACKAGE_MANAGER" in
        npm)
            echo "  CI cache key: 'npm'"
            echo "  CI install command: 'npm ci'"
            ;;
        yarn)
            echo "  CI cache key: 'yarn'"
            echo "  CI install command: 'yarn install --frozen-lockfile'"
            echo "  Add 'corepack enable' for yarn berry"
            ;;
        pnpm)
            echo "  CI cache key: 'pnpm'"
            echo "  CI install command: 'pnpm install --frozen-lockfile'"
            echo "  Use: pnpm/action-setup@v4"
            ;;
        bun)
            echo "  CI cache key: 'bun'"
            echo "  CI install command: 'bun install --frozen-lockfile'"
            echo "  Use: oven-sh/setup-bun@v2"
            ;;
    esac
fi

# Check for common framework configs
echo ""
echo "🔧 Checking framework configuration..."

if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
    echo -e "${GREEN}✓ Vite config found${NC}"
fi

if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
    echo -e "${GREEN}✓ Next.js config found${NC}"
    # Check if using static export
    if grep -q "output: 'export'" next.config.* 2>/dev/null; then
        echo -e "${GREEN}✓ Static export configured${NC}"
    else
        echo -e "${YELLOW}⚠ Static export not configured${NC}"
        echo "  Add: output: 'export' to next.config.js"
    fi
fi

if [ -f "nuxt.config.ts" ] || [ -f "nuxt.config.js" ]; then
    echo -e "${GREEN}✓ Nuxt config found${NC}"
fi

if [ -f "vue.config.js" ]; then
    echo -e "${GREEN}✓ Vue CLI config found${NC}"
fi

if [ -f "angular.json" ]; then
    echo -e "${GREEN}✓ Angular config found${NC}"
fi

# Check for GitHub Actions workflows
echo ""
echo "⚙️  Checking GitHub Actions..."

if [ -d ".github/workflows" ]; then
    WORKFLOW_COUNT=$(ls -1 .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null | wc -l)
    if [ "$WORKFLOW_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $WORKFLOW_COUNT workflow(s)${NC}"
        ls -1 .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null | while read -r wf; do
            echo "  - $(basename "$wf")"
        done
    else
        echo -e "${YELLOW}⚠ .github/workflows exists but no YAML files${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠ No .github/workflows directory${NC}"
    echo "  Create deployment workflow to enable CI/CD"
    ERRORS=$((ERRORS + 1))
fi

# Check for CNAME file
echo ""
echo "🌐 Checking domain configuration..."
if [ -f "CNAME" ]; then
    DOMAIN=$(cat CNAME | tr -d '[:space:]')
    echo -e "${GREEN}✓ CNAME found: $DOMAIN${NC}"
else
    echo -e "${YELLOW}⚠ No CNAME file${NC}"
    echo "  Add CNAME file for custom domain"
fi

# Check for common build output directories
echo ""
echo "📁 Checking build output..."
OUTPUT_DIRS=("dist" "build" "out" ".next" ".output")
FOUND_OUTPUT=0

for dir in "${OUTPUT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓ Found output directory: $dir${NC}"
        FOUND_OUTPUT=1
    fi
done

if [ $FOUND_OUTPUT -eq 0 ]; then
    echo -e "${YELLOW}⚠ No build output directory found${NC}"
    echo "  Run build command to generate output"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for .gitignore
echo ""
echo "🙈 Checking .gitignore..."
if [ -f ".gitignore" ]; then
    echo -e "${GREEN}✓ .gitignore exists${NC}"

    # Check for node_modules
    if grep -q "node_modules" .gitignore; then
        echo -e "${GREEN}✓ node_modules ignored${NC}"
    else
        echo -e "${YELLOW}⚠ node_modules not in .gitignore${NC}"
    fi
else
    echo -e "${RED}✗ No .gitignore file${NC}"
    echo "  Create .gitignore to exclude build artifacts"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Ready for deployment${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Found $WARNINGS warning(s). Review before deployment${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
