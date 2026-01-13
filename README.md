# Claude Skills 合集

本项目包含用于扩展 Claude AI 能力的各种 Skills。

## Skills 列表

### github-deploy

**功能说明：** 完整的 GitHub 部署解决方案，用于静态站点、前端应用和 Node 脚本的自动化部署。

**主要功能：**
- 静态站点部署（HTML/CSS/JS）
- 前端框架构建部署（React/Vue/Next.js/Nuxt 等）
- Node 脚本部署（NPM 包发布或 GitHub Release）
- GitHub Actions 工作流配置
- 自定义域名与 HTTPS 配置
- 多环境部署支持（开发/生产）

**适用场景：**
- 部署到 GitHub Pages
- 设置 CI/CD 工作流
- 配置自定义域名
- 部署无服务器 Node 应用

**详细信息：** 查看 [github-deploy/SKILL.md](./github-deploy/SKILL.md)

---

## 使用说明

每个 skill 都包含详细的文档和示例。在需要使用特定功能时，可以引用对应的 skill 来获取专业的指导和自动化流程。

## 项目结构

```
claude_skills/
├── README.md           # 本文件
└── github-deploy/      # GitHub 部署 skill
    ├── SKILL.md        # Skill 详细文档
    ├── references/     # 参考文档
    └── scripts/        # 辅助脚本
```
