# 提交前检查清单

用于 GitHub 作业平台提交前自检。

## 1. 仓库完整性

- [x] 项目包含 Godot 工程配置：`project.godot`
- [x] 项目包含主入口场景：`res://UI/LevelSelect.tscn`
- [x] 项目包含核心源码、场景、资源、技能表和文档
- [x] 提交历史连续，能体现真实开发过程
- [x] README 已说明项目、功能、主要系统、运行方式和提交记录
- [x] Milestone 划分建议已记录在 `docs/milestones.md`

## 2. 敏感信息

- [x] 未发现密钥、令牌、客户数据、内部服务地址等敏感信息
- [x] 本地 Godot 存档路径仅使用 `user://*.cfg`，不是仓库内密钥
- [x] `.gitignore` 已忽略 `export_credentials.cfg`
- [x] `.gitignore` 已忽略本地工具目录 `.dsh/`
- [x] `.DS_Store` 已从 Git 跟踪中移除

## 3. Godot 上传质量

- [x] `.godot/`、`.import/`、导出目录等本地生成目录已忽略
- [x] Godot `.import` 文件按当前项目习惯保留，保证资源引用稳定
- [x] `skill_list.csv` 与 `docs/skills.md` 均在仓库内
- [x] 程序化生成脚本保留在 `tools/`

## 4. 平台流程

1. 在 GitHub 创建仓库。
2. 将本地仓库推送到 GitHub。
3. 在作业平台填写 GitHub Repo 地址并完成 GitHub App 授权。
4. 等待平台上传仓库与提交历史。
5. 依次完成准入检查和 Repo 质量检查。
6. 参照 `docs/milestones.md` 创建 Milestone。
7. 完成 Milestone 质量检查。
8. 三阶段均通过后提交题目。

## 5. 推荐推送命令

如果 GitHub remote 名称为 `github`：

```bash
git push github develop:develop
```

如果 GitHub remote 名称为 `origin`：

```bash
git push origin develop:develop
```

如果需要同时推送 GitHub 和 Gitee：

```bash
git push github develop:develop
git push origin develop:develop
```

具体远程名称以 `git remote -v` 输出为准。

