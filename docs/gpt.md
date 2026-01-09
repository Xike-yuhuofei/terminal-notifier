## 最推荐的组合：Tab 标题前缀 + 进度环（红色 Error）+ 可选闪烁 + 一键清除

### 1) 用“改 Tab 标题”精确定位到触发的那一页

Windows Terminal 支持用 bash 直接设置标题，例如：`echo -ne "\033]0;New Title\a"`，而且也解释了 `suppressApplicationTitle` 会影响是否允许应用改标题。 ([Microsoft Learn][1])

> 你想要“红色闪烁标题”——**Windows Terminal 的 tab 标题文字颜色本身通常不能按 tab 单独改成红色**（UI 控制的），但你可以用：

* 标题前缀 emoji/符号（🔴 / ❗ / [ATTN]）
* 标题内容闪烁（在两个标题之间来回切换）

这样视觉上也非常强。

---

### 2) 用“进度环/任务栏进度”做更强的视觉提醒（而且真的很直观）

Windows Terminal 支持 ConEmu 的 **OSC 9;4 进度序列**，会在**tab 头部显示进度环**，并且还能在**Windows 任务栏**显示进度状态。格式是：`ESC ] 9 ; 4 ; <state> ; <progress> BEL`，其中 `state=2` 是 **Error**（通常是红色态）。 ([Microsoft Learn][2])

这非常适合拿来当“红色告警灯”：

* Notification/Stop 一触发：立刻 `state=2; progress=100` → tab 上出现红色进度环
* 处理完：`state=0` 清掉

---

### 3) 用 Windows Terminal 的 bellStyle 让“窗口/任务栏也闪一下”（可选）

你说不想只靠声音/Toast，那就把 **bellStyle** 开成 `taskbar` 或 `all`，让 BEL 触发时任务栏也闪。Windows Terminal 配置项支持 `"all" | "audible" | "window" | "taskbar" | "none"`。 ([Microsoft Learn][3])

---

## Claude Code 侧：用 Stop / Notification Hook 调脚本，把“当前 tab”标记出来

Claude Code hook 的输入里就有 `hook_event_name`，Notification 还有 `message / notification_type / cwd`，Stop 有 `stop_hook_active` 等字段。 ([Claude Code][4])
Hook 配置也支持 `type:"command"`，并且可用 `$CLAUDE_PROJECT_DIR` 指到项目内脚本。 ([Claude Code][4])

### A) `.claude/settings.local.json`（建议用 local，不提交）

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/wt-attn.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/wt-attn.sh" }
        ]
      }
    ]
  }
}
```

### B) `.claude/hooks/wt-attn.sh`（关键：改标题 + 红色进度环 + 可选闪烁）

> 下面脚本思路是：读 stdin JSON → 提取 event/cwd/message → 设置标题 → 设置红色进度环 →（可选）闪烁 10 秒

```bash
#!/usr/bin/env bash
set -euo pipefail

# 读 hook JSON（Claude Code 会通过 stdin 传入）:contentReference[oaicite:5]{index=5}
payload="$(cat)"

# 用 python 做 JSON 提取（Git Bash 通常有 python；没有就换成 jq）
event="$(python - <<'PY'
import json,sys
j=json.loads(sys.stdin.read())
print(j.get("hook_event_name",""))
PY
<<<"$payload")"

cwd="$(python - <<'PY'
import json,sys
j=json.loads(sys.stdin.read())
print(j.get("cwd",""))
PY
<<<"$payload")"

msg="$(python - <<'PY'
import json,sys
j=json.loads(sys.stdin.read())
print(j.get("message",""))
PY
<<<"$payload")"

ntype="$(python - <<'PY'
import json,sys
j=json.loads(sys.stdin.read())
print(j.get("notification_type",""))
PY
<<<"$payload")"

# repo 名（可选）
repo="$cwd"
if [[ -n "$cwd" ]] && command -v git >/dev/null 2>&1; then
  top="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$top" ]]; then repo="$(basename "$top")"; fi
fi

# 1) 标题：前缀醒目 + 事件类型 + repo
# Windows Terminal/bash 设置标题：echo -ne "\033]0;New Title\a" :contentReference[oaicite:6]{index=6}
title="🔴 Claude ${event}"
if [[ "$event" == "Notification" ]]; then
  title+=" (${ntype})"
fi
title+=" | ${repo}"

echo -ne "\033]0;${title}\a"

# 2) 进度环：Error 红色态 + 100%
# OSC 9;4;state;progress BEL，state=2 为 Error :contentReference[oaicite:7]{index=7}
echo -ne "\033]9;4;2;100\a"

# 3) 可选：闪烁 10 秒（标题/进度环交替）
(
  for i in {1..20}; do
    echo -ne "\033]0;${title}\a"
    echo -ne "\033]9;4;2;100\a"
    sleep 0.25
    echo -ne "\033]0;${repo}\a"
    echo -ne "\033]9;4;0;0\a"
    sleep 0.25
  done
  # 闪完保持“红环+标题”在那，直到你手动清除
  echo -ne "\033]0;${title}\a"
  echo -ne "\033]9;4;2;100\a"
) >/dev/null 2>&1 & disown

# 4) 同时打一行大字（tab 内也能看到）
echo
echo "========== ATTENTION: ${event} | ${repo} =========="
[[ -n "$msg" ]] && echo "$msg"
echo "=================================================="
echo
```

### C) 一键清除（建议加到你的 `~/.bashrc`）

```bash
claude_clear_attn() {
  # 清标题（换回 cwd 或你喜欢的默认）
  echo -ne "\033]0;$(basename "$PWD")\a"
  # 清进度环：state=0 :contentReference[oaicite:8]{index=8}
  echo -ne "\033]9;4;0;0\a"
}
alias cclear='claude_clear_attn'
```

---

## 关键注意点（避免你装好后“怎么没效果/一闪就没了”）

1. **别把 `suppressApplicationTitle` 设成 true**（否则应用改标题会被压制）。Windows Terminal 文档明确提到这个开关会“抑制应用改标题”。 ([Microsoft Learn][1])

2. **你的 bash prompt / oh-my-posh / 主题可能会频繁重写标题**
   如果你发现标题被抢回去了，就把“设置标题”的逻辑做成 PROMPT_COMMAND 里“读一个状态文件”的模式：hook 只写状态文件，prompt 每次显示前决定标题该不该带🔴（这样就不会被覆盖）。

3. **Stop hook 可能会“继续运行”导致反复触发**
   Stop 输入里有 `stop_hook_active`，官方提示用它避免无限循环。 ([Claude Code][4])
   （比如 `stop_hook_active=true` 时你就只做提示、不做任何会导致 Claude 继续的动作。）

---

## 你要的“更像红色闪烁 tab”的进阶选项（可选）

除了上面的“进度环闪烁”，还有更激进的做法：用 Windows Terminal 支持的颜色表/别名映射（一些是私有/非官方文档化）去改 tab 背景色，然后在红/默认之间切换做“真·红闪”。社区里有人总结了可行的转义序列方案（含 `FRAME_BACKGROUND` 等特殊项）。([Super User][5])
这个我会建议当“进阶/实验功能”，因为它可能影响你主题、而且不同版本行为可能会变。
