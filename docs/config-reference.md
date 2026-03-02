# OpenClaw 配置参考（新用户标准）

> 本文件是项目唯一配置口径：API、模型和渠道统一维护在 `~/.openclaw/openclaw.json`。

## 1) 最小可用配置（推荐直接复制后改值）

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

## 2) 强校验规则
- `models.providers.openai.baseUrl`：必须是 `baseUrl`（小写 `l`），不是 `baseURL`。
- `models.providers.openai.api`：默认示例 `openai-completions`。
- `models.providers.openai.apiKey`：必须存在，且不写入 Git。
- `models.providers.openai.models`：必须是非空数组。
- `agents.defaults.model.primary`：必须是 `provider/model`，例如 `openai/glm-4.7`。
- `agents.defaults.model.fallbacks`：推荐配置为 `openai/<model>` 数组。
- `channels.feishu.connectionMode`：建议固定 `websocket`。
- 首次接入飞书：`dmPolicy=pairing`，验收通过后改 `allowlist` + `allowFrom`。

## 3) 飞书接入顺序（关键）
1. 飞书创建应用，拿 `appId/appSecret`。
2. 先写入 `openclaw.json` 并重启服务。
3. 再在飞书后台配置长连接、事件（`im.message.receive_v1`）、权限并发布版本。
4. 私聊机器人触发 pairing，请求在服务侧 approve。
5. 稳定后切 `dmPolicy=allowlist` 并设置 `allowFrom`。

## 4) 错误对照与修复

| 现象 | 常见原因 | 处理 |
|---|---|---|
| `Unrecognized key: "baseURL"` | 键名写错 | 改为 `baseUrl` 后重启 |
| `models.providers.openai.models: expected array` | 漏填 `models[]` | 补齐非空数组后重启 |
| `Unknown model: anthropic/<model>` | `primary` 未写 provider | 改为 `openai/<model>` |
| `No pending feishu pairing requests` | 未触发私聊或策略非 `pairing` | 设 `dmPolicy=pairing` 后私聊触发 |
| 飞书不回消息 | 权限未开/版本未发布 | 补齐权限并发布版本后重测 |

## 5) 安全注意
- 密钥只存本机，严禁提交 Git。
- 每次改配置都执行：备份 -> JSON 校验 -> 权限修复 -> 重启 -> 验收。
- 若密钥泄露，立即轮换并重启服务。
