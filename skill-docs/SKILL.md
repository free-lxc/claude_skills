---
name: skill-docs
description: 通用Skill分析工具，帮助AI快速理解和解析任意Claude Skill的配置、功能和使用方法。通过分析skill的SKILL.md文件，提取关键信息，生成易于理解的技能摘要。
---

# Skill Docs

通用Skill分析工具，帮助AI快速理解和解析任意Claude Skill。

## 功能概述

当需要理解一个skill的结构、功能和使用方式时使用此工具。它可以：

- **解析Skill配置**: 提取skill的name、description等front matter信息
- **分析功能特性**: 从skill内容中识别核心功能、使用场景和关键特性
- **生成技能摘要**: 创建结构化的skill概览，便于快速理解
- **提取使用示例**: 识别文档中的代码示例和配置片段
- **理解参数定义**: 分析skill的参数格式和可选值

## Skill文件格式标准

Claude Skill通常遵循以下结构：

### 基本格式

```markdown
---
name: skill-name
description: 技能的详细描述...
optionalParam1: value1
optionalParam2: value2
---

# 技能标题

技能详细内容...
```

### Front Matter字段

| 字段 | 必需 | 说明 |
|------|------|------|
| `name` | ✅ | Skill的唯一标识符，用于调用 |
| `description` | ✅ | Skill的功能描述 |
| 其他字段 | ❌ | Skill特定的配置参数 |

## 分析流程

### 1. 识别Skill边界

从SKILL.md中提取：
- **Skill名称**: `name`字段
- **功能定义**: `description`字段
- **调用方式**: 如何通过Skill工具调用

### 2. 解析功能结构

分析文档内容，识别：
- **核心功能**: skill主要解决什么问题
- **使用场景**: 什么时候应该使用这个skill
- **输入参数**: 需要什么参数或配置
- **输出结果**: 会产生什么结果或输出

### 3. 提取关键信息

从文档中提取：
- **代码示例**: 实际使用示例
- **配置模板**: 可复制的配置代码
- **注意事项**: 使用时需要注意的点
- **相关资源**: 引用的其他文档或链接

## 使用方式

### 分析本地Skill文件

```
请分析 /path/to/skill/SKILL.md 文件
```

### 理解Skill功能

```
请解释 <skill-name> skill的功能和使用方法
```

### 对比多个Skill

```
请对比 <skill-name-1> 和 <skill-name-2> 的功能差异
```

### 提取Skill配置

```
请提取 <skill-name> skill的所有配置参数
```

## 输出格式

分析一个skill时会生成以下结构化输出：

### 基础信息
```yaml
name: skill-name
description: 功能描述摘要
```

### 功能分析
- **核心能力**: 3-5个关键功能点
- **适用场景**: 推荐的使用场景列表
- **不适用场景**: 不推荐使用的场景

### 使用指南
- **调用方式**: `skill: "name"` 或 `/<name>`
- **参数说明**: 各参数的含义和格式
- **示例代码**: 实际使用示例

### 关联信息
- **依赖项**: 需要的其他工具或技能
- **相关Skill**: 功能相似或互补的skill
- **参考资源**: 相关文档链接

## Skill类型识别

工具可以识别以下常见skill类型：

| 类型 | 特征 | 示例 |
|------|------|------|
| **代码生成** | 包含代码模板、生成逻辑 | component-generator |
| **部署工具** | 包含CI/CD配置、部署流程 | github-deploy |
| **文档工具** | 包含文档解析、格式转换 | doc-generator |
| **分析工具** | 包含解析、检查、诊断功能 | skill-docs |
| **测试工具** | 包含测试运行、断言逻辑 | test-runner |

## 最佳实践

### 编写易于理解的Skill

1. **清晰的描述**: description应简洁说明skill的用途
2. **结构化内容**: 使用标题、列表组织内容
3. **具体示例**: 提供可运行的代码示例
4. **参数说明**: 明确说明每个参数的作用

### 使用此工具分析Skill

1. **从front matter开始**: 先理解skill的基本信息
2. **关注核心功能**: 识别skill解决的核心问题
3. **查看示例代码**: 通过示例理解使用方式
4. **检查依赖关系**: 确认需要的前置条件

## 示例

### 输入
```
请分析一个名为 "github-deploy" 的skill
```

### 输出示例
```
## Skill分析: github-deploy

### 基本信息
- **名称**: github-deploy
- **类型**: 部署工具
- **描述**: 完整的GitHub部署解决方案，支持自动检测包管理器

### 核心功能
1. 静态站点部署到GitHub Pages
2. 自动包管理器检测(npm/yarn/pnpm/bun)
3. GitHub Actions工作流生成
4. 自定义域名配置

### 使用场景
- 部署React/Vue/Next.js等前端应用
- 设置静态网站托管
- 配置CI/CD自动化流程

### 调用方式
```
skill: "github-deploy"
args: "配置参数"
```

### 关键配置
- 工作流文件: `.github/workflows/deploy.yml`
- 包管理器: 自动检测或手动指定
- 部署分支: 默认为gh-pages
```
