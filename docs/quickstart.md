# 快速开始（新用户 5 步）

> 本文只覆盖当前标准：使用 `openclaw.json` 一次性完成 API、模型、飞书配置。

## Step 1) 预检
```bash
bash scripts/preflight.sh
```

## Step 2) 填写 `openclaw.json`
- 位置：`/Users/svc_openclaw/.openclaw/openclaw.json`
- 必填字段：
  - `models.providers.openai.baseUrl`
  - `models.providers.openai.api`（默认 `openai-completions`）
  - `models.providers.openai.apiKey`
  - `models.providers.openai.models[]`
  - `agents.defaults.model.primary`
  - `agents.defaults.model.fallbacks[]`（推荐）
  - `channels.feishu.*`

## Step 3) 重启服务使配置生效
```bash
sudo launchctl kickstart -k system/com.openclaw.service
```

## Step 4) 飞书平台配置（先本地后平台）
1. 本地先写好 `openclaw.json` 的 `channels.feishu.accounts.default`。  
2. 再去飞书后台配置：
- 长连接（WebSocket）
- 事件：`im.message.receive_v1`
- 消息权限
- 发布版本

## Step 5) pairing -> allowlist -> 验收
1. `dmPolicy=pairing` 时先触发并批准 pairing。  
2. 验证通过后改 `dmPolicy=allowlist` + `allowFrom=[ou_xxx]`。  
3. 验收：
```bash
bash scripts/verify-service.sh
bash scripts/check-feishu.sh
```

通过标准：
- 服务 `running`
- 3030 端口监听
- 进程属主 `svc_openclaw`
- 日志无阻断错误
- Feishu 通道（启用时）为 `running/works`
