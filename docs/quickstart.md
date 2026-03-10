# 快速开始（新用户 5 步）

> 只走一套流程：编辑项目内 `openclaw.json`，再覆盖服务配置。

## Step 1) 预检
```bash
bash scripts/preflight.sh
```

## Step 2) 准备并编辑项目配置
在仓库根目录：
```bash
cp templates/openclaw.json.template openclaw.json
```
然后用任意图形编辑器打开 `openclaw.json`，填写 API、模型和飞书字段。

## Step 3) 校验并覆盖服务配置
```bash
python3 -m json.tool openclaw.json >/dev/null && echo OK
sudo install -o svc_openclaw -g staff -m 600 openclaw.json /Users/svc_openclaw/.openclaw/openclaw.json
sudo launchctl kickstart -k system/com.openclaw.service
```

## Step 4) 飞书平台配置（先本地后平台）
1. 本地 `openclaw.json` 先写好 `channels.feishu.accounts.default`。  
2. 飞书后台再配置：长连接（WebSocket）+ `im.message.receive_v1` + 权限 + 发布版本。

## Step 5) pairing -> allowlist -> 验收
1. `dmPolicy=pairing` 时先触发并批准 pairing。  
2. 验证通过后改 `dmPolicy=allowlist` + `allowFrom=[ou_xxx]`。  
3. 验收：
```bash
sudo launchctl print system/com.openclaw.service | grep -E "state =|pid ="
lsof -nP -iTCP:3030 -sTCP:LISTEN
```
