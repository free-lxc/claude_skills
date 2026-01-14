# Claude Skills 合集

本项目包含用于扩展 Claude AI 能力的各种 Skills。

## Skills 列表

### github-deploy

**功能说明：** 完整的 GitHub 部署解决方案，支持自动检测包管理器（npm/yarn/pnpm/bun）并生成匹配的 CI/CD 工作流。

**核心功能：**
- **自动包管理器检测** - 通过 lock 文件自动识别 npm/yarn/pnpm/bun
- **静态站点部署** - 直接部署 HTML/CSS/JS 到 GitHub Pages
- **框架构建部署** - 支持 React/Vue/Next.js/Nuxt/Angular 等框架
- **多环境部署** - 支持 staging/production 分环境部署
- **自定义域名配置** - 支持 CNAME 和 DNS 配置
- **Node 脚本部署** - NPM 包发布或 GitHub Release

**支持的包管理器：**

| Lock 文件 | 包管理器 | 安装命令 |
|-----------|----------|----------|
| `package-lock.json` | npm | `npm ci` |
| `yarn.lock` | yarn v1 | `yarn install --frozen-lockfile` |
| `yarn.lock` + `.yarn/cache` | yarn v3+ | `yarn install --immutable` |
| `pnpm-lock.yaml` | pnpm | `pnpm install --frozen-lockfile` |
| `bun.lockb` | bun | `bun install --frozen-lockfile` |

**部署决策树：**

```
项目类型?
├── 静态站点 (HTML/CSS/JS)      → Static Pages Workflow
├── 前端框架 (React/Vue)         → Framework Build Workflow
├── 全栈框架 (Next.js/Nuxt)      → Static Export Workflow
├── Node 脚本/应用               → Node Deployment Workflow
└── 需要自定义域名?              → Domain Configuration Step
```

**使用场景与工作流对应：**

| 场景 | 工作流 | 构建输出目录 |
|------|--------|-------------|
| 纯静态网站 | Static Pages Workflow | `/` |
| React/Vite | Framework Build Workflow | `dist/` |
| Vue CLI | Framework Build Workflow | `dist/` |
| Create React App | Framework Build Workflow | `build/` |
| Next.js 静态导出 | Framework Build Workflow | `out/` |
| NPM 包发布 | Node Script Deployment | - |

**详细信息：** 查看 [github-deploy/SKILL.md](./github-deploy/SKILL.md)

---

### skill-docs

**功能说明：** 通用 Skill 分析工具，帮助 AI 快速理解和解析任意 Claude Skill 的配置、功能和使用方法。

**主要功能：**
- 解析 Skill 配置（name、description 等 front matter 信息）
- 分析功能特性（核心功能、使用场景、关键特性）
- 生成技能摘要（结构化的 skill 概览）
- 提取使用示例（代码示例和配置片段）
- 理解参数定义（参数格式和可选值）
- Skill 类型识别（代码生成/部署工具/文档工具/分析工具/测试工具）

**适用场景：**
- 理解任意 skill 的结构和用法
- 分析 skill 文件的配置参数
- 对比多个 skill 的功能差异
- 生成 skill 的功能摘要

**详细信息：** 查看 [skill-docs/SKILL.md](./skill-docs/SKILL.md)

---

### novel-fanfiction

**功能说明：** 小说二次创作工具，支持基于原作小说进行续写、改写、风格转换、视角转换、情节拓展等多种二创形式。

**核心功能：**
- **剧情续写** (Continue) - 基于原作设定和情节走向，续写新的章节内容
- **情节改写** (Rewrite) - 对指定章节或情节进行重新创作，改变叙事风格或结构
- **风格转换** (Style) - 将原作内容转换为不同的文学风格（古龙风、金庸风、翻译腔、网络文学风等）
- **视角转换** (POV) - 从不同角色的视角重述相同的故事
- **情节拓展** (Expand) - 在原有情节基础上增加细节、心理描写和场景刻画
- **平行宇宙** (AU) - 保留核心角色设定，改变世界观背景进行创作
- **假设性场景** (What If) - 探索关键情节的不同可能性分支
- **跨作品联动** (Crossover) - 将不同作品的世界观和角色进行融合创作

**支持的文学风格：**

| 风格类型 | 特点 | 代表风格 |
|---------|------|---------|
| 古典武侠 | 用词典雅，句式整齐，意境深远 | 金庸、古龙 |
| 网络文学 | 语言轻快，节奏明快，爽点密集 | 玄幻、都市爽文 |
| 翻译腔 | 句式欧化，倒装结构，用词精准 | 外国文学翻译 |
| 意识流 | 内心独白，思维跳跃，联想丰富 | 乔伊斯、伍尔夫 |
| 纪实风格 | 客观冷静，细节详实，注重事实 | 报道文学 |
| 黑色幽默 | 荒诞讽刺，轻松外表沉重内核 | 冯内古特、海勒 |

**适用场景：**
- 同人创作：基于喜欢的作品进行二次创作
- 写作练习：通过改写和视角转换提升写作技巧
- 创意拓展：为卡住的剧情寻找新的可能性
- 风格实验：尝试不同的叙事风格和语言方式
- 情节优化：对初稿进行润色和改进

**详细信息：** 查看 [novel-fanfiction/SKILL.md](./novel-fanfiction/SKILL.md)

---

## 使用说明

每个 skill 都包含详细的文档和示例。在需要使用特定功能时，可以引用对应的 skill 来获取专业的指导和自动化流程。

## 项目结构

```
claude_skills/
├── README.md              # 本文件
├── github-deploy/         # GitHub 部署 skill
│   ├── SKILL.md           # Skill 详细文档
│   ├── references/        # 参考文档
│   │   ├── ADVANCED_WORKFLOWS.md
│   │   ├── DOMAIN_SETUP.md
│   │   ├── FRAMEWORK_CONFIGS.md
│   │   └── PACKAGE_MANAGER_CONFIG.md
│   └── scripts/           # 辅助脚本
│       └── validate_setup.sh
├── skill-docs/            # Skill 分析工具
│   ├── SKILL.md           # Skill 详细文档
│   └── references/        # 参考文档
└── novel-fanfiction/      # 小说二创 skill
    ├── SKILL.md           # Skill 详细文档
    └── references/        # 参考文档
        ├── WRITING_STYLES.md    # 写作风格参考
        └── POV_GUIDE.md         # 叙事视角指南
```
