# OpenClaw macOS 隔离部署：新手手把手手动指南

> 目标：你自己从零完成部署，不依赖 Agent 自动执行。  
> 场景：主用户 A 日常使用 macOS，服务用户 B（`svc_openclaw`）隔离运行 OpenClaw。

---

## 0. 你将完成什么
完成后你会得到：
1. `svc_openclaw` 用户运行 OpenClaw 后台服务。  
2. 服务由 `launchd` 托管，系统重启后可自动拉起。  
3. API 使用 OpenAI-compatible 配置。  
4. 飞书机器人可以收发消息（先 pairing，后 allowlist）。

默认值：
- 服务用户：`svc_openclaw`
- 服务标签：`com.openclaw.service`
- 生产配置：`/Users/svc_openclaw/.openclaw/openclaw.json`
- 工作配置（项目内）：`./openclaw.json`
- 端口：`3030`

---

## 1. 开始前准备
```bash
sw_vers
node -v
npm -v
jq --version || echo "jq missing (optional)"
```

---

## 2. 创建服务用户（已有则跳过）
在系统设置创建 `svc_openclaw`，然后：
```bash
id svc_openclaw
```

---

## 3. 创建目录
```bash
sudo install -d -o svc_openclaw -g staff -m 755 /Users/svc_openclaw/apps
sudo install -d -o svc_openclaw -g staff -m 755 /Users/svc_openclaw/etc
sudo install -d -o svc_openclaw -g staff -m 755 /Users/svc_openclaw/var/openclaw
sudo install -d -o svc_openclaw -g staff -m 755 /Users/svc_openclaw/logs/openclaw
sudo install -d -o svc_openclaw -g staff -m 700 /Users/svc_openclaw/.openclaw
```

---

## 4. 安装 OpenClaw（服务用户）
```bash
sudo -u svc_openclaw zsh -lc 'cd /Users/svc_openclaw && export NPM_CONFIG_PREFIX=/Users/svc_openclaw/.local/npm; mkdir -p /Users/svc_openclaw/.local/npm; npm install -g openclaw@latest'
sudo -u svc_openclaw zsh -lc 'ls -l /Users/svc_openclaw/.local/npm/bin/openclaw'
```

---

## 5. 写启动脚本
```bash
sudo tee /Users/svc_openclaw/apps/start-openclaw.sh >/dev/null <<'SH'
#!/bin/zsh
set -euo pipefail
export HOME=/Users/svc_openclaw
export PATH=/Users/svc_openclaw/.local/npm/bin:$PATH
cd /Users/svc_openclaw
exec /Users/svc_openclaw/.local/npm/bin/openclaw gateway serve
SH

sudo chown svc_openclaw:staff /Users/svc_openclaw/apps/start-openclaw.sh
sudo chmod 755 /Users/svc_openclaw/apps/start-openclaw.sh
```

---

## 6. 准备并编辑项目配置（统一模板）

在仓库根目录执行：
```bash
cp templates/openclaw.json.template openclaw.json
```

然后直接用任意图形编辑器打开项目文件 `openclaw.json`，填写：
- `models.providers.openai.baseUrl`
- `models.providers.openai.api`（默认 `openai-completions`）
- `models.providers.openai.apiKey`
- `models.providers.openai.models[]`
- `agents.defaults.model.primary`
- `agents.defaults.model.fallbacks[]`（推荐）
- `channels.feishu.*`

校验并覆盖生产配置：
```bash
python3 -m json.tool openclaw.json >/dev/null && echo OK
sudo install -o svc_openclaw -g staff -m 600 openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json
```

---

## 7. 写 launchd 服务文件
```bash
sudo tee /Library/LaunchDaemons/com.openclaw.service.plist >/dev/null <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.openclaw.service</string>
  <key>UserName</key><string>svc_openclaw</string>
  <key>ProgramArguments</key>
  <array><string>/Users/svc_openclaw/apps/start-openclaw.sh</string></array>
  <key>WorkingDirectory</key><string>/Users/svc_openclaw</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>StandardOutPath</key><string>/Users/svc_openclaw/logs/openclaw/stdout.log</string>
  <key>StandardErrorPath</key><string>/Users/svc_openclaw/logs/openclaw/stderr.log</string>
</dict>
</plist>
PLIST

sudo chown root:wheel /Library/LaunchDaemons/com.openclaw.service.plist
sudo chmod 644 /Library/LaunchDaemons/com.openclaw.service.plist
```

---

## 8. 启动服务
```bash
sudo launchctl bootstrap system /Library/LaunchDaemons/com.openclaw.service.plist
sudo launchctl enable system/com.openclaw.service
sudo launchctl kickstart -k system/com.openclaw.service
```

---

## 9. 第一次验收
```bash
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```

---

## 10. 飞书接入（按顺序）
1. 飞书后台创建应用，拿 `App ID` / `App Secret`。  
2. 回到项目根目录编辑 `openclaw.json` 中 `channels.feishu.accounts.default`。  
3. 执行：
```bash
python3 -m json.tool openclaw.json >/dev/null && echo OK
sudo install -o svc_openclaw -g staff -m 600 openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json
sudo launchctl kickstart -k system/com.openclaw.service
```
4. 再去飞书后台配置：长连接 + `im.message.receive_v1` + 权限 + 发布版本。  
5. `dmPolicy=pairing` 时私聊触发 pairing 并 approve。  
6. 稳定后改 `allowlist + allowFrom`。

---

## 11. 配置修改标准流程（以后都按这个）
每次改配置都在仓库根目录执行：
```bash
# 1) 备份项目工作文件
cp openclaw.json openclaw.json.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null || true

# 2) 直接用图形编辑器修改 openclaw.json

# 3) 校验
python3 -m json.tool openclaw.json >/dev/null && echo OK

# 4) 覆盖生产配置
sudo install -o svc_openclaw -g staff -m 600 openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json

# 5) 重启
sudo launchctl kickstart -k system/com.openclaw.service

# 6) 快速验收
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```

---

## 12. 常见报错
- `baseURL`：改为 `baseUrl`。
- `Unknown model: anthropic/...`：`primary` 改为 `openai/<model>`。
- `No pending feishu pairing requests`：检查 `dmPolicy=pairing`、私聊触发、飞书权限/发布。

---

## 13. 回滚
```bash
# 用项目备份回滚
cp openclaw.json.bak.<timestamp> openclaw.json
python3 -m json.tool openclaw.json >/dev/null && echo OK
sudo install -o svc_openclaw -g staff -m 600 openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json
sudo launchctl kickstart -k system/com.openclaw.service
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```

---

## 14. 安全提醒
- 不提交带密钥的 `openclaw.json`。
- 密钥泄露立即轮换并重启服务。

---

## 15. 后续用 cc-switch 切换 API（可选）
- 首次部署可用后可安装 `cc-switch`。
- 关键注意：切到 `svc_openclaw` GUI 会话再打开 `cc-switch`，否则可能检测不到该实例。
- 切换后仍按第 11 节统一流程执行。
