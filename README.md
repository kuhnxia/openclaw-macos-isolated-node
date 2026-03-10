# OpenClaw macOS Isolated Node

> 给新用户的目标：在一台 macOS 上，让主用户正常工作，同时让服务用户隔离运行 OpenClaw（launchd 托管）。

## 你会得到什么
- 主用户（A）继续日常使用 macOS。
- 服务用户（B，默认 `svc_openclaw`）独立运行 OpenClaw。
- API 侧按 OpenAI-compatible 配置。
- 聊天渠道以飞书机器人为主示例。

## 先选一种安装方式

### 方式 A（推荐）：Agent 引导安装
适合第一次部署，按提示确认即可。

1. 进入仓库
```bash
git clone <YOUR_REPO_URL>
cd openclaw-macos-isolated-node
```
2. 打开 Codex 或 Claude Code。  
3. 复制并发送安装提示词（二选一）
```bash
cat prompts/codex-install.txt
# 或
cat prompts/claude-install.txt
```
提示词文件链接：[prompts/codex-install.txt](prompts/codex-install.txt) / [prompts/claude-install.txt](prompts/claude-install.txt)
4. 按提示确认：`sudo`、API Key、Provider、聊天渠道。  
5. 完成后执行验收（任意目录可执行）：
```bash
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```
（可选）仓库内完整验收脚本：[scripts/verify-service.sh](scripts/verify-service.sh)

### 方式 B：纯手动安装
适合愿意全程手工配置的用户。直接看：
- [docs/manual-setup.md](docs/manual-setup.md)

## 你需要提前准备
- 一个服务用户（建议：`svc_openclaw`）。
- API Key（OpenAI-compatible 提供方）。
- 飞书应用的 `App ID` 和 `App Secret`（如果要启用飞书）。

## 新用户最容易踩坑的 4 件事
1. `baseURL` 写错：必须是 `baseUrl`。  
2. `primary` 没写 provider：必须是 `openai/<model>`。  
3. 飞书顺序错误：先把 `appId/appSecret` 写进 OpenClaw 并重启，再去飞书配置长连接事件。  
4. 配置改完流程不统一：统一执行 `编辑项目 openclaw.json -> json校验 -> sudo install -> kickstart -> 验收`。

## 后续改 API（cc-switch）
- 第一次配置跑通后，可以安装 `cc-switch` 做后续 API 切换。
- 关键注意：必须切换到 `svc_openclaw` 的 GUI 会话中打开 `cc-switch`，它才能检测并修改该用户下的 OpenClaw 配置。

## 手工改配置（统一操作法）
- 在仓库根目录直接打开并编辑 `openclaw.json`（任意图形编辑器）。
- 然后执行：
```bash
python3 -m json.tool openclaw.json >/dev/null && echo OK
sudo install -o svc_openclaw -g staff -m 600 openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json
sudo launchctl kickstart -k system/com.openclaw.service
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```

## 飞书接入顺序（务必按这个来）
1. 飞书创建应用，拿 `appId/appSecret`。  
2. 先写入 OpenClaw 配置并重启服务。  
3. 再在飞书后台配置：长连接（WebSocket）+ `im.message.receive_v1` + 权限 + 发布版本。  
4. 私聊机器人触发 pairing，服务侧 approve。  
5. 稳定后把 `dmPolicy` 从 `pairing` 切到 `allowlist`。

## 一分钟验收清单
```bash
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```
（可选）仓库内脚本链接：[scripts/preflight.sh](scripts/preflight.sh) / [scripts/verify-service.sh](scripts/verify-service.sh) / [scripts/check-feishu.sh](scripts/check-feishu.sh)

通过标准：
- 服务 `running`
- 3030 端口监听
- 进程属主是 `svc_openclaw`
- 日志无阻断错误
- Feishu 通道（启用时）显示 `running/works`

## 安全边界
- 密钥不要提交到 Git。
- 本仓库只放模板和流程，不放你的生产密钥与本机专属成品配置。
- 若密钥泄露，立即轮换并重启服务。

## 服务清零（删除 `svc_openclaw` 前）
如果你准备删除服务用户，先把服务清理干净，避免系统残留无效自启动：

```bash
# 1) 停止并卸载服务
sudo launchctl bootout system /Library/LaunchDaemons/com.openclaw.service.plist
sudo rm -f /Library/LaunchDaemons/com.openclaw.service.plist

# 2) 可选：备份配置
sudo cp -R /Users/svc_openclaw/.openclaw /Users/rocky/Desktop/openclaw-backup-$(date +%Y%m%d%H%M%S)

# 3) 验证已清理
sudo launchctl print system/com.openclaw.service || echo \"service removed\"
```

然后再去系统设置删除 `svc_openclaw` 用户。

## 文档导航
- 配置参考（字段定义与错误对照）：[docs/config-reference.md](docs/config-reference.md)
- 手动部署（全流程命令版）：[docs/manual-setup.md](docs/manual-setup.md)
- 快速开始（Agent 视角）：[docs/quickstart.md](docs/quickstart.md)
- 日常运维：[docs/ops.md](docs/ops.md)
- 故障排查：[docs/troubleshooting.md](docs/troubleshooting.md)
- Self-Ops Skill（交给 OpenClaw 执行配置改动）：[prompts/openclaw-self-ops-skill.txt](prompts/openclaw-self-ops-skill.txt)
