# OpenClaw 配置参考（新用户唯一口径）

> API、模型和飞书渠道统一配置在项目根目录的 `openclaw.json`，再覆盖到 `/Users/svc_openclaw/.openclaw/openclaw.json`。

## 1) 标准配置示例

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "openai": {
        "baseUrl": "https://your-openai-compatible-endpoint/v1",
        "api": "openai-completions",
        "apiKey": "YOUR_API_KEY",
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
          "appId": "cli_xxx",
          "appSecret": "xxx"
        }
      }
    }
  }
}
```

## 2) 统一模板操作（首次安装 / 后续改配置通用）

在仓库根目录执行：

```bash
# Step 0) 首次准备（仅第一次）
cp templates/openclaw.json.template openclaw.json

# Step 1) 直接用图形编辑器打开项目文件 openclaw.json 并修改

# Step 2) 校验
python3 -m json.tool openclaw.json >/dev/null && echo OK

# Step 3) 覆盖服务配置
sudo install -o svc_openclaw -g staff -m 600 openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json

# Step 4) 重启
sudo launchctl kickstart -k system/com.openclaw.service

# Step 5) 简版验收
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```

## 3) 字段检查清单（每次都看）
- `models.providers.openai.baseUrl`（不是 `baseURL`）
- `models.providers.openai.api`（默认 `openai-completions`）
- `models.providers.openai.apiKey`
- `models.providers.openai.models[]`（非空）
- `agents.defaults.model.primary`（`openai/<model>`）
- `agents.defaults.model.fallbacks[]`（推荐）
- `channels.feishu.connectionMode=websocket`
- 首次联调 `dmPolicy=pairing`，稳定后 `allowlist + allowFrom`

## 4) 飞书接入顺序（关键）
1. 飞书创建应用，拿 `appId/appSecret`。
2. 先在项目内改 `openclaw.json` 并覆盖到服务配置后重启。
3. 再在飞书后台配置长连接、事件（`im.message.receive_v1`）、权限并发布版本。
4. 私聊机器人触发 pairing，请求在服务侧 approve。
5. 稳定后切 `dmPolicy=allowlist` 并设置 `allowFrom`。

## 5) 常见错误
- `Unrecognized key: "baseURL"`：改为 `baseUrl`。
- `models.providers.openai.models: expected array`：补齐非空 `models[]`。
- `Unknown model: anthropic/<model>`：`primary` 改成 `openai/<model>`。
- 飞书不回消息：优先检查权限和发布版本。

## 6) 安全边界
- 不提交带密钥的 `openclaw.json`。
- 每次改配置都按“统一模板操作”执行。
- 密钥泄露后立即轮换并重启服务。
