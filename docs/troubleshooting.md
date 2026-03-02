# 故障排查（新用户标准）

## 1) `baseURL` 无效
- 现象：`Unrecognized key: "baseURL"`。
- 原因：键名写错。
- 处理：改为 `baseUrl`，重启服务。

## 2) `models[]` 缺失或为空
- 现象：`models.providers.openai.models: expected array`。
- 原因：未配置模型数组或数组为空。
- 处理：补齐 `models.providers.openai.models` 非空数组，重启服务。

## 3) `primary` 未带 provider
- 现象：`Unknown model: anthropic/<model>`。
- 原因：`agents.defaults.model.primary` 未写 `provider/model`。
- 处理：改为 `openai/<model>`，并建议配置 `fallbacks`。

## 4) 飞书没有 pending pairing 请求
- 现象：`openclaw pairing list feishu` 为空。
- 原因：
  - `dmPolicy` 不是 `pairing`；
  - 未私聊机器人触发请求；
  - 飞书平台事件或发布未生效。
- 处理：
  1. 设 `dmPolicy=pairing`
  2. 私聊机器人发送一条消息
  3. 确认飞书后台已配置事件并发布版本

## 5) 飞书不回消息
- 现象：机器人能收到但不回复。
- 原因：常见为权限未开或版本未发布。
- 处理：
  1. 飞书后台补齐消息相关权限（含 cardkit 相关权限，按日志提示）
  2. 发布新版本
  3. 重启服务并复测

## 6) `uv_cwd EACCES`
- 现象：`Error: EACCES: process.cwd failed`。
- 原因：在服务用户无权限目录执行 `sudo -u svc_openclaw ...`。
- 处理：先 `cd /Users/svc_openclaw`，或使用：
```bash
bash scripts/safe-openclaw-cli.sh channels status --probe
```

## 7) 快速诊断顺序
1. `bash scripts/preflight.sh`
2. `sudo launchctl kickstart -k system/com.openclaw.service`
3. `bash scripts/verify-service.sh`
4. `bash scripts/check-feishu.sh`
