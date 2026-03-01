# 日常运维 Runbook

## 1) 重启后自检（30 秒）
```bash
# 用户执行或 Agent 代执行
bash scripts/verify-service.sh
```

## 2) 常用命令
```bash
# 查看状态（用户执行 / Agent 代执行）
sudo launchctl print system/com.openclaw.service

# 重启服务（用户执行 / Agent 代执行）
sudo launchctl kickstart -k system/com.openclaw.service

# 停止服务（用户执行 / Agent 代执行）
sudo launchctl bootout system /Library/LaunchDaemons/com.openclaw.service.plist

# 启动服务（用户执行 / Agent 代执行）
sudo launchctl bootstrap system /Library/LaunchDaemons/com.openclaw.service.plist
sudo launchctl enable system/com.openclaw.service
```

## 3) 改配置流程（备份 -> 修改 -> 重启 -> 验收）
```bash
# 1) 备份（用户执行 / Agent 代执行）
cp /Users/svc_openclaw/etc/openclaw.env /Users/svc_openclaw/etc/openclaw.env.bak.$(date +%Y%m%d%H%M%S)

# 2) 修改（用户执行：编辑器；或 Agent 代执行）
# vi /Users/svc_openclaw/etc/openclaw.env

# 3) 重启（用户执行 / Agent 代执行）
sudo launchctl kickstart -k system/com.openclaw.service

# 4) 验收（用户执行 / Agent 代执行）
bash scripts/verify-service.sh
```

## 4) 升级与回滚
- 升级前记录当前 commit/tag。
- 升级后先做最小验收（状态、端口、日志、一次对话）。
- 如失败，回退到上一版本并重启服务。
- 保留 env 备份，避免配置丢失。

## 5) 故障排查顺序
1. `launchctl print` 看退出码与状态。
2. 看 `stderr.log` 首条错误。
3. 查端口是否冲突。
4. 查文件权限和属主。
5. 查 env 变量名和密钥是否缺失。
