# 日常运维 Runbook

## 1) 重启后自检（30 秒）
```bash
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```

## 2) 常用命令
```bash
sudo launchctl print system/com.openclaw.service
sudo launchctl kickstart -k system/com.openclaw.service
sudo launchctl bootout system /Library/LaunchDaemons/com.openclaw.service.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.openclaw.service.plist
sudo launchctl enable system/com.openclaw.service
```

## 3) 改配置（统一模板）
在仓库根目录执行：
```bash
# 1) 编辑项目配置 openclaw.json（图形编辑器）

# 2) 校验
python3 -m json.tool openclaw.json >/dev/null && echo OK

# 3) 覆盖服务配置
sudo install -o svc_openclaw -g staff -m 600 openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json

# 4) 重启
sudo launchctl kickstart -k system/com.openclaw.service

# 5) 验收
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```

## 4) 飞书专项检查
```bash
bash scripts/check-feishu.sh
```

## 5) 升级与回滚
- 升级前记录当前 commit/tag。
- 升级后先做最小验收（状态、端口、一次对话）。
- 如失败，回退到上一版本并重启服务。

## 6) 日志阅读规范
1. 先看本次重启后的最近日志。
2. 优先看阻断错误：`Config invalid` / `Unknown model` / `No API key` / 权限拒绝。
3. `duplicate plugin id` 常见为非阻断警告。
