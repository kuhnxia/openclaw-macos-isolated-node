# OpenClaw macOS Isolated Node

> 仓库只提供模板与流程。密钥、系统级安装、用户路径与权限变更都在用户本机由 Agent 经确认后执行，不写入 Git。

## 架构概览（30 秒）
- 主工作账户（用户 A）用于日常 GUI 工作负载。
- 独立服务账户（用户 B，默认 `svc_openclaw`）用于运行 OpenClaw 后台进程。
- 在单台 macOS 主机上实现多用户隔离部署与并行运行。

## 这个项目是做什么的
本项目提供一套 macOS 本地部署方案，使同一主机上的两个账户职责分离：
- 用户 A：交互式桌面会话（GUI）与日常业务操作。
- 用户 B：服务运行账户，托管 OpenClaw 长驻进程（由 `launchd` 管理）。

## 这样做的 4 个优势
- **权限与数据隔离**：服务账户与工作账户分离，运行数据、日志和配置文件位于独立用户目录，降低相互影响。
- **并行执行**：交互式工作负载与后台服务负载并发运行，避免会话切换导致服务中断。
- **本地可控部署**：服务与数据驻留本机，便于本地网络策略、访问控制与审计。
- **低基础设施成本**：无需新增物理主机或云实例，单机即可完成部署与运维。

## 你只需要手动做什么
- 创建服务用户（默认示例：`svc_openclaw`，可改名）。
- 准备密钥（API Key、渠道 Token）。
- 选择 Provider 和聊天渠道（安装时由 Agent 提问确认）。
- 在系统级命令前确认 `sudo` 授权。

## Agent 会替你做什么
- 初始化目录与文件模板。
- 渲染本机配置（env、启动脚本、plist）。
- 安装并管理 launchd 服务。
- 执行验收检查（状态、端口、日志）。

## 快速开始
1. 拉取并进入仓库（**用户执行**）
```bash
git clone <YOUR_REPO_URL>
cd openclaw-macos-isolated-node
```
2. 在该目录打开 Codex 或 Claude Code（**用户执行**）。
3. 把安装 Prompt 全文贴给 Agent（**用户执行**）
```bash
# 二选一
cat prompts/codex-install.txt
cat prompts/claude-install.txt
```
4. 按 Agent 提问确认关键项（**用户执行**）
- `sudo` 授权
- 密钥填写
- Provider 选择
- 聊天渠道选择
5. 让 Agent 完成预检、安装和验收（**Agent 代执行**）。

## 详细步骤
1. 预检（**Agent 代执行**）
```bash
bash scripts/preflight.sh
```
2. 安装前准备（**Agent 代执行 + 用户确认**）
- Agent 初始化目录与模板。
- 用户确认服务用户、网络路径（有/无 VPN）。
3. 安装与配置（**Agent 代执行 + 用户确认**）
- Agent 根据你选择的 Provider/渠道渲染本机配置。
- 用户提供密钥并确认写入。
4. 服务化启动（**Agent 代执行 + 用户确认 sudo**）
- Agent 配置并启动 launchd 服务。
5. 验收（**Agent 代执行**）
```bash
bash scripts/verify-service.sh
```
6. 日常运维（**用户执行或 Agent 代执行**）
- 安装后使用 `prompts/codex-ops.txt` 或 `prompts/claude-ops.txt` 做重启、改配置、升级、回滚。

## 命令标签说明
- `用户执行`：你在终端手动执行。
- `Agent 代执行`：由 Codex/Claude Code 执行，关键步骤会先向你确认。

## 文档导航
- 快速开始：`docs/quickstart.md`
- 日常运维：`docs/ops.md`
- 故障排查：`docs/troubleshooting.md`
