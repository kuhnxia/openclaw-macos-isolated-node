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

默认值（文中都按这个写）：
- 服务用户：`svc_openclaw`
- 服务标签：`com.openclaw.service`
- OpenClaw 配置：`/Users/svc_openclaw/.openclaw/openclaw.json`
- 服务日志目录：`/Users/svc_openclaw/logs/openclaw`
- 端口：`3030`

---

## 1. 开始前准备（5 分钟）

### 1.1 确认你在 macOS 终端
打开 Terminal，执行：
```bash
sw_vers
```
看到 macOS 版本信息即可。

### 1.2 确认 Node/npm
```bash
node -v
npm -v
```
如果报 `command not found`，先安装 Node LTS（建议 20+）。

### 1.3 建议安装 jq（用于校验 JSON）
```bash
jq --version
```
如果没有 jq，不影响部署，但排错会更慢。

### 1.4 你需要准备的账号信息
- API 提供方：Base URL、API Key、模型名。
- 飞书应用：`App ID`、`App Secret`。

---

## 2. 创建服务用户（如果已经有就跳过）

在“系统设置 -> 用户与群组”创建标准用户 `svc_openclaw`。  
创建后执行：
```bash
id svc_openclaw
```
出现 uid/gid 说明创建成功。

---

## 3. 创建目录（必须）

执行：
```bash
sudo install -d -o svc_openclaw -g staff -m 755 /Users/svc_openclaw/apps
sudo install -d -o svc_openclaw -g staff -m 755 /Users/svc_openclaw/etc
sudo install -d -o svc_openclaw -g staff -m 755 /Users/svc_openclaw/var/openclaw
sudo install -d -o svc_openclaw -g staff -m 755 /Users/svc_openclaw/logs/openclaw
sudo install -d -o svc_openclaw -g staff -m 700 /Users/svc_openclaw/.openclaw
```

验证：
```bash
ls -ld /Users/svc_openclaw/{apps,etc,var/openclaw,logs/openclaw,.openclaw}
```

看到目录都存在即可。

---

## 4. 安装 OpenClaw（服务用户）

执行：
```bash
sudo -u svc_openclaw zsh -lc 'cd /Users/svc_openclaw && export NPM_CONFIG_PREFIX=/Users/svc_openclaw/.local/npm; mkdir -p /Users/svc_openclaw/.local/npm; npm install -g openclaw@latest'
```

验证：
```bash
sudo -u svc_openclaw zsh -lc 'ls -l /Users/svc_openclaw/.local/npm/bin/openclaw'
```

如果能看到文件路径，说明安装成功。

---

## 5. 写启动脚本（让服务固定以服务用户环境运行）

创建脚本：
```bash
sudo tee /Users/svc_openclaw/apps/start-openclaw.sh >/dev/null <<'SH'
#!/bin/zsh
set -euo pipefail
export HOME=/Users/svc_openclaw
export PATH=/Users/svc_openclaw/.local/npm/bin:$PATH
cd /Users/svc_openclaw
exec /Users/svc_openclaw/.local/npm/bin/openclaw gateway serve
SH
```

设置权限：
```bash
sudo chown svc_openclaw:staff /Users/svc_openclaw/apps/start-openclaw.sh
sudo chmod 755 /Users/svc_openclaw/apps/start-openclaw.sh
```

验证：
```bash
head -n 20 /Users/svc_openclaw/apps/start-openclaw.sh
```

---

## 6. 写 OpenClaw 主配置（API + 飞书）

> 这一步最关键，字段名不要写错。

### 6.1 先创建配置文件
```bash
sudo tee /Users/svc_openclaw/.openclaw/openclaw.json >/dev/null <<'JSON'
{
  "gateway": {
    "mode": "local",
    "auth": {
      "enabled": true,
      "token": "REPLACE_GATEWAY_TOKEN"
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "openai": {
        "baseUrl": "https://api.openai.com/v1",
        "api": "openai-completions",
        "apiKey": "REPLACE_OPENAI_API_KEY",
        "models": [
          { "id": "kimi-k2.5", "name": "kimi-k2.5" },
          { "id": "qwen3-max", "name": "qwen3-max" },
          { "id": "deepseek-v3.2", "name": "deepseek-v3.2" }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/kimi-k2.5",
        "fallbacks": [
          "openai/qwen3-max",
          "openai/deepseek-v3.2"
        ]
      }
    }
  },
  "channels": {
    "feishu": {
      "enabled": true,
      "domain": "feishu",
      "connectionMode": "websocket",
      "dmPolicy": "pairing",
      "groupPolicy": "open",
      "accounts": {
        "default": {
          "appId": "REPLACE_FEISHU_APP_ID",
          "appSecret": "REPLACE_FEISHU_APP_SECRET"
        }
      }
    }
  }
}
JSON
```

### 6.2 用编辑器替换占位符（使用 vim）
```bash
sudo vim /Users/svc_openclaw/.openclaw/openclaw.json
```
替换以下字段：
- `REPLACE_GATEWAY_TOKEN`
- `baseUrl`
- `api`（默认推荐 `openai-completions`）
- `apiKey`（写在 `models.providers.openai.apiKey`）
- `models[].id/name`
- `primary` 与 `fallbacks`
- `REPLACE_FEISHU_APP_ID`
- `REPLACE_FEISHU_APP_SECRET`

vim 常用键：
- 进入编辑：按 `i`
- 退出编辑模式：按 `Esc`
- 保存并退出：输入 `:wq` 后回车
- 不保存退出：输入 `:q!` 后回车
- 查找：输入 `/关键词` 后回车

### 6.3 修权限并校验
```bash
sudo chown svc_openclaw:staff /Users/svc_openclaw/.openclaw/openclaw.json
sudo chmod 600 /Users/svc_openclaw/.openclaw/openclaw.json
sudo python3 -m json.tool /Users/svc_openclaw/.openclaw/openclaw.json >/dev/null && echo OK
```

如果 `OK` 没出现，说明 JSON 有语法错误，回去修。

### 6.4 三个最容易写错的地方
1. `baseUrl` 必须是这个拼写，不能写 `baseURL`。  
2. `models` 必须是数组。  
3. `primary` 必须是 `openai/<model>`，不能只写模型名。

---

## 7. 写 launchd 服务文件

创建 plist：
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
```

设置权限：
```bash
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

如果 `bootstrap` 提示已存在，可用：
```bash
sudo launchctl bootout system /Library/LaunchDaemons/com.openclaw.service.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.openclaw.service.plist
sudo launchctl enable system/com.openclaw.service
sudo launchctl kickstart -k system/com.openclaw.service
```

---

## 9. 第一次验收（必须）

```bash
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
ps -o user,pid,command -ax | grep -E "[o]penclaw|[n]ode.*openclaw"
tail -n 80 /Users/svc_openclaw/logs/openclaw/stderr.log
```

你应看到：
- `state = running`
- 3030 有监听
- 进程用户是 `svc_openclaw`
- 日志没有持续阻断报错

---

## 10. 飞书接入（按顺序，不要跳步）

### 10.1 飞书后台先建应用，拿凭据
拿到：
- `App ID`
- `App Secret`

### 10.2 先写入 openclaw.json 并重启服务
```bash
sudo vim /Users/svc_openclaw/.openclaw/openclaw.json
sudo python3 -m json.tool /Users/svc_openclaw/.openclaw/openclaw.json >/dev/null && echo OK
sudo chown svc_openclaw:staff /Users/svc_openclaw/.openclaw/openclaw.json
sudo chmod 600 /Users/svc_openclaw/.openclaw/openclaw.json
sudo launchctl kickstart -k system/com.openclaw.service
```

### 10.3 再去飞书后台做事件与权限
- 事件订阅：`长连接（WebSocket）`
- 事件：`im.message.receive_v1`
- 开消息相关权限（至少收/发消息）
- 发布新版本

### 10.4 触发 pairing
你在飞书私聊机器人发一句话。若机器人返回 `Pairing code`，到终端执行：
```bash
sudo -u svc_openclaw zsh -lc 'cd /Users/svc_openclaw && export HOME=/Users/svc_openclaw PATH=/Users/svc_openclaw/.local/npm/bin:$PATH; openclaw pairing approve feishu <CODE>'
```

查看 pending：
```bash
sudo -u svc_openclaw zsh -lc 'cd /Users/svc_openclaw && export HOME=/Users/svc_openclaw PATH=/Users/svc_openclaw/.local/npm/bin:$PATH; openclaw pairing list feishu'
```

### 10.5 转正式策略（推荐）
把 `dmPolicy` 从 `pairing` 改为 `allowlist`，并加上你的 `open_id`：
```json
"allowFrom": ["ou_xxx"]
```

改完后重启：
```bash
sudo launchctl kickstart -k system/com.openclaw.service
```

---

## 11. 配置修改标准流程（以后都按这个）

每次你改 `openclaw.json`，都执行：
```bash
# 1) 备份
cp /Users/svc_openclaw/.openclaw/openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json.bak.$(date +%Y%m%d%H%M%S)

# 2) 修改
sudo vim /Users/svc_openclaw/.openclaw/openclaw.json

# 3) 校验
sudo python3 -m json.tool /Users/svc_openclaw/.openclaw/openclaw.json >/dev/null && echo OK

# 4) 权限
sudo chown svc_openclaw:staff /Users/svc_openclaw/.openclaw/openclaw.json
sudo chmod 600 /Users/svc_openclaw/.openclaw/openclaw.json

# 5) 重启
sudo launchctl kickstart -k system/com.openclaw.service

# 6) 验收
bash scripts/verify-service.sh
```

---

## 12. 常见报错与快速处理

### 12.1 `Unknown model: anthropic/...`
原因：`primary` 没写 provider。  
修复：改成 `openai/<model>`。

### 12.2 `baseURL` 相关报错
原因：键名写错。  
修复：改成 `baseUrl`。

### 12.3 `No pending feishu pairing requests`
原因：未触发消息、`dmPolicy` 不是 pairing、飞书权限或发布未生效。  
修复：按第 10 章顺序逐项核对。

### 12.4 `uv_cwd EACCES`
原因：在服务用户无权限目录运行 `sudo -u svc_openclaw ...`。  
修复：命令前先 `cd /Users/svc_openclaw`。

### 12.5 `pyenv: cannot rehash`
通常是 shell 初始化噪音，一般不阻断 OpenClaw。

---

## 13. 回滚（改坏了怎么办）

如果刚改完就异常，回退到最近备份：
```bash
ls -lt /Users/svc_openclaw/.openclaw/openclaw.json.bak.* | head
sudo cp /Users/svc_openclaw/.openclaw/openclaw.json.bak.<timestamp> /Users/svc_openclaw/.openclaw/openclaw.json
sudo chown svc_openclaw:staff /Users/svc_openclaw/.openclaw/openclaw.json
sudo chmod 600 /Users/svc_openclaw/.openclaw/openclaw.json
sudo launchctl kickstart -k system/com.openclaw.service
bash scripts/verify-service.sh
```

---

## 14. 安全提醒（务必）
- 不要把 API Key / 飞书 secret 提交到 Git。
- 不要把密钥贴到公开聊天或截图。
- 一旦泄露，立即去平台后台轮换密钥并重启服务。

---

## 15. 后续用 cc-switch 切换 API（可选）
- 第一次部署完成并验证可用后，可以安装 `cc-switch` 管理 API 配置切换。
- 关键注意：请先切换到 `svc_openclaw` 的 GUI 会话，再打开 `cc-switch`。
- 原因：OpenClaw 配置在服务用户目录下，`cc-switch` 只有在对应用户会话中才能正确检测到该实例并修改配置。
- 切换后仍按标准流程执行：
  1. JSON 校验
  2. `chown/chmod`
  3. `sudo launchctl kickstart -k system/com.openclaw.service`
  4. `bash scripts/verify-service.sh`
