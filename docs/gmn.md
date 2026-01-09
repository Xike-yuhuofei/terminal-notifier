---

## 核心方案：利用 OSC 转义序列控制 Windows Terminal

Windows Terminal 能够识别特定的控制字符来改变标签页的颜色、标题以及任务栏状态。

### 1. 效果设计

* **标签页变色**：触发 Hook 时，将标签页背景色设为红色（最直观）。
* **标题前缀**：在标题前加入 `[DONE]` 或 `[!]`。
* **任务栏进度条变红**：即使终端在后台，任务栏图标也会显示红色警告色。

### 2. 脚本实现 (Bash 脚本)

由于你使用 Git Bash，我们可以写一个通用的通知脚本 `notify_me.sh`：

```bash
#!/bin/bash

# 1. 设置标签页颜色为红色 (RGB: 255, 0, 0)
echo -ne "\e]6;1;bg;red;brightness;255\a"
echo -ne "\e]6;1;bg;green;brightness;0\a"
echo -ne "\e]6;1;bg;blue;brightness;0\a"

# 2. 修改标签页标题，加入警告符号
echo -ne "\033]2;⚠️ Claude Needs Attention!\033\\"

# 3. 设置任务栏状态为 "错误/停止" (红色状态指示)
# OSC 9;4;st\a  (st: 0=无, 1=进度, 2=错误, 3=忙碌, 4=暂停)
echo -ne "\e]9;4;2;100\a"

# 4. (可选) 触发系统提示音
echo -ne "\a"

```

### 3. 集成到 Claude Code Hook

在你的项目根目录下的 Claude Code 配置文件（通常是 `.claudecode.json` 或类似的 Hook 配置位置）中，将 `notification` 或 `stop` Hook 指向该脚本：

```json
{
  "hooks": {
    "onNotification": "bash ~/scripts/notify_me.sh",
    "onStop": "bash ~/scripts/notify_me.sh"
  }
}

```

---

## 进阶：如何“恢复”正常状态？

当你的视觉提醒触发后，标签页会一直保持红色。为了更好的体验，你需要一个**恢复机制**：当你重新点击该 Tab 并输入命令时，自动将颜色重置。

### 方案：利用 `PROMPT_COMMAND`

在你的 `.bashrc` 中添加一段代码，每当你执行完命令回到输入提示符时，自动重置终端状态：

```bash
# 重置 Windows Terminal 状态的函数
reset_term_status() {
    # 重置标签页颜色 (去掉颜色，恢复默认)
    echo -ne "\e]6;1;bg;red;brightness;default\a"
    # 重置任务栏进度条
    echo -ne "\e]9;4;0;0\a"
}

# 每次显示提示符前执行
PROMPT_COMMAND="reset_term_status; $PROMPT_COMMAND"

```

---

## 方案汇总表

| 提醒方式 | 物理实现指令 (ANSI/OSC) | 视觉效果 |
| --- | --- | --- |
| **标签页背景色** | `\e]6;1;bg;r;g;b\a` | 整个 Tab 标签背景变红，极其显眼。 |
| **标题闪烁/修改** | `\033]2;新标题\a` | 标题文字改变，配合 Emoji 很容易定位。 |
| **任务栏状态** | `\e]9;4;2;100\a` | 任务栏图标下方出现红色横条，全局可见。 |
| **视觉铃声** | `\a` | 若 Windows Terminal 开启了 Visual Bell，屏幕会闪烁。 |

---

### 建议操作步骤：

1. **确认 Windows Terminal 设置**：确保“外观”设置中没有禁用“允许脚本修改标题”。
2. **编写脚本**：将上述 `notify_me.sh` 保存到你的常用工具目录。
3. **配置 Claude**：在 `CLAUDE_CODE_NOTIFY_CMD` 环境变量或配置文件中调用该脚本。
4. **测试**：在 Git Bash 中直接运行 `echo -ne "\e]6;1;bg;red;brightness;255\a"` 看看你的标签页是否立刻变红。

这样一来，当你开了一堆窗口时，哪个窗口变红了，就说明哪个 Claude Code 需要你处理，效率直接拉满。

