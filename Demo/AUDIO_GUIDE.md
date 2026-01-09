# Claude Code 提示音配置指南

## 📋 配置摘要

基于 UX 最佳实践和 Windows 11 音频设计原则，为 Claude Code 的 Stop 和 Notification 事件配置了优化的提示音方案。

---

## 🎵 音频选择及理由

### Notification Hook - 需要用户输入
**选用音频**: `C:\Windows\Media\Windows Notify.wav`

**设计理由**:
- ✅ **语义明确**: Windows 官方"通知"音效，用户立刻理解含义
- ✅ **频率适中**: 低频事件（偶尔需要输入），使用较明显的提醒音
- ✅ **压力友好**: Windows 11 "less stressful" 设计哲学，不刺耳
- ✅ **原生体验**: 与系统其他通知保持一致，降低学习成本

**心理学依据**:
- 根据 [UX 设计指南](https://ux.stackexchange.com/questions/122026/ux-design-guidelines-for-audio-sound-feedback-and-interaction-of-ui)，需要用户关注的事件应使用**明显但不刺耳**的音效
- [Material Design 音频指南](https://m2.material.io/design/sound/applying-sound-to-ui.html)强调：提示性音效应使用中等音量、清晰但友好的声音

---

### Stop Hook - 任务完成
**选用音频**: `C:\Windows\Media\tada.wav`

**设计理由**:
- ✅ **积极情感**: "Ta-da!" 效果音传递成功、完成的愉悦感
- ✅ **高频优化**: Stop 事件触发频繁，使用轻快的音效避免疲劳
- ✅ **奖励机制**: 正强化，提升用户工作动力和满意度
- ✅ **Windows 经典**: 用户熟悉的成功音效，跨版本一致

**心理学依据**:
- [Microsoft Sound Design](https://microsoft.design/articles/the-sound-of-innovation-how-audio-designers-are-redefining-digital-experiences/) 强调：成功反馈音应传递"成就感和积极情绪"
- [Smashing Magazine 音频设计指南](https://www.smashingmagazine.com/2012/09/guidelines-for-designing-with-audio/)指出：高频事件应使用**简短、轻柔**的音效避免听觉疲劳

---

## 🎯 音频设计原则（基于最佳实践）

### 1. **分层音效系统**
```
低频事件（Notification）→ 更明显的音效（Windows Notify.wav）
高频事件（Stop）        → 更轻快的音效（tada.wav）
```

参考：[Claude Code Sounds 社区讨论](https://daveschumaker.net/claude-sounds-better-notifications-for-claude-code/)

### 2. **WCAG 无障碍合规** ✅
- ✅ **双重反馈**: 视觉通知（桌面气泡）+ 听觉提示（音频）
- ✅ **可配置性**: 用户可轻松修改 `settings.json` 更换或禁用音频
- ✅ **不依赖单一感官**: 符合 [WCAG 1.3.3](https://wcag.dock.codes/documentation/wcag133/) 规范

参考：[Web Accessibility Initiative 听觉指南](https://www.w3.org/WAI/people-use-web/abilities-barriers/auditory/)

### 3. **Windows 官方指南遵循** ✅
- ✅ 使用系统自带音频文件（C:\Windows\Media\）
- ✅ 遵循 [Windows UX 声音指南](https://learn.microsoft.com/en-us/windows/win32/uxguide/vis-sound)
- ✅ 集成 Windows 11 "calmer sounds" 设计语言

参考：[Windows 11 声音效果个性化](https://reelmind.ai/blog/windows-11-sound-effects-personalize-your-experience/)

### 4. **用户体验优化** ✅
- ✅ **非侵入式**: 音频时长 < 2 秒，不打断心流
- ✅ **音量适中**: 使用系统音量，尊重用户设置
- ✅ **优雅降级**: 音频文件缺失时自动静默，不影响通知显示

---

## 🛠️ 技术实现

### 脚本文件
- **位置**: `~/.claude/tools/terminal-notifier/notify-with-sound.ps1`
- **功能**: Windows Forms 通知 + 可选音频播放
- **容错**: 音频失败时自动降级到静默模式

### 配置示例
```json
{
  "hooks": {
    "Notification": [{
      "hooks": [{
        "type": "command",
        "command": "powershell.exe -ExecutionPolicy Bypass -File ~/.claude/tools/terminal-notifier/notify-with-sound.ps1 -Title 'Claude Code' -Message '需要您的输入 ⚠️' -Sound 'C:\\Windows\\Media\\Windows Notify.wav'"
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "powershell.exe -ExecutionPolicy Bypass -File ~/.claude/tools/terminal-notifier/notify-with-sound.ps1 -Title 'Claude Code' -Message '任务完成 ✅' -Sound 'C:\\Windows\\Media\\tada.wav'"
      }]
    }]
  }
}
```

---

## 🎨 其他可选音频方案

### Windows 系统音频备选
| 事件类型 | 推荐音频 | 文件路径 | 特点 |
|---------|---------|---------|------|
| Notification | `Windows Notify Email.wav` | `C:\Windows\Media\` | 类似默认，稍柔和 |
| Notification | `chimes.wav` | `C:\Windows\Media\` | 清脆悦耳 |
| Stop | `ding.wav` | `C:\Windows\Media\` | 极简成功音 |
| Stop | `chord.wav` | `C:\Windows\Media\` | 和弦成功音 |

### 自定义音频
用户可使用任何 `.wav` 文件：
```json
"-Sound 'C:\\path\\to\\custom\\sound.wav'"
```

**推荐音频属性**:
- 格式：WAV (PCM)
- 采样率：44.1kHz 或 48kHz
- 位深度：16-bit
- 时长：1-2 秒
- 音量：已标准化到 -3dB

---

## 🧪 测试方法

### 测试 Notification 提示音
```powershell
powershell.exe -ExecutionPolicy Bypass -File ~/.claude/tools/terminal-notifier/notify-with-sound.ps1 `
  -Title "测试通知" `
  -Message "需要您的输入" `
  -Sound "C:\Windows\Media\Windows Notify.wav"
```

### 测试 Stop 提示音
```powershell
powershell.exe -ExecutionPolicy Bypass -File ~/.claude/tools/terminal-notifier/notify-with-sound.ps1 `
  -Title "测试通知" `
  -Message "任务完成" `
  -Sound "C:\Windows\Media\tada.wav"
```

---

## 🔧 高级配置

### 禁用音频（仅桌面通知）
将 `-Sound` 参数改为空字符串或删除：
```json
"command": "powershell.exe -ExecutionPolicy Bypass -File ~/.claude/tools/terminal-notifier/notify.ps1 -Title 'Claude Code' -Message '消息'"
```

### 调整音量
修改 `~/.claude/tools/terminal-notifier/notify-with-sound.ps1` 脚本，添加音量控制：
```powershell
# 在播放音频前添加
$soundPlayer.Volume = 0.5  # 0.0 到 1.0
```

### 更换音频文件
1. 找到喜欢的 `.wav` 文件
2. 修改 `settings.json` 中的 `-Sound` 参数路径
3. 重启 Claude Code 或重新加载配置

---

## 📚 参考资料

### 音频设计最佳实践
- [Windows UX Sound Guidelines](https://learn.microsoft.com/en-us/windows/win32/uxguide/vis-sound)
- [Material Design - Applying Sound to UI](https://m2.material.io/design/sound/applying-sound-to-ui.html)
- [Smashing Magazine: Guidelines for Designing with Audio](https://www.smashingmagazine.com/2012/09/guidelines-for-designing-with-audio/)
- [UX StackExchange: Audio Feedback Guidelines](https://ux.stackexchange.com/questions/122026/ux-design-guidelines-for-audio-sound-feedback-and-interaction-of-ui)

### Claude Code 音频社区
- [claude-sounds: better notifications](https://daveschumaker.net/claude-sounds-better-notifications-for-claude-code/)
- [Claude Code Terminal Bell Notifications - Reddit](https://www.reddit.com/r/ClaudeAI/comments/1kpt4za/claude_code_terminal_bell_notifications/)
- [Completion Notifications with Hooks](https://plusadd.medium.com/completion-notifications-with-hooks-in-claude-code-banner-voice-4cc766d19fda)

### 无障碍设计
- [WCAG 1.3.3: Sensory Characteristics](https://wcag.dock.codes/documentation/wcag133/)
- [WAI: Auditory Disabilities](https://www.w3.org/WAI/people-use-web/abilities-barriers/auditory/)
- [Audio Accessibility Best Practices](https://www.accessibilitychecker.org/blog/audio-accessibility/)

### Windows 音频技术
- [Custom Audio on Toast Notifications](https://learn.microsoft.com/en-us/windows/apps/develop/notifications/app-notifications/custom-audio-on-toasts)
- [Windows 11 Notification Sounds](https://www.ctrl.blog/entry/windows-alert-sounds.html)

---

## 🎉 总结

本配置方案严格遵循以下原则：

1. ✅ **UX 最佳实践**: 分层音效系统，高频轻柔、低频明显
2. ✅ **无障碍合规**: 视觉+听觉双重反馈，可配置可禁用
3. ✅ **原生体验**: 使用 Windows 官方音频，降低学习成本
4. ✅ **情绪设计**: 成功音效传递积极情绪，提升满意度
5. ✅ **工程健壮**: 容错降级，音频失败不影响通知显示

**Sources**:
- [Windows UX Sound Guidelines - Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/uxguide/vis-sound)
- [Material Design: Applying Sound to UI](https://m2.material.io/design/sound/applying-sound-to-ui.html)
- [UX StackExchange: Audio Feedback Guidelines](https://ux.stackexchange.com/questions/122026/ux-design-guidelines-for-audio-sound-feedback-and-interaction-of-ui)
- [Claude Sounds: Better Notifications](https://daveschumaker.net/claude-sounds-better-notifications-for-claude-code/)
- [Windows 11 Gets New and Less Stressful Notification Sounds - Ctrl.blog](https://www.ctrl.blog/entry/windows-alert-sounds.html)
- [Microsoft Design: The Sound of Innovation](https://microsoft.design/articles/the-sound-of-innovation-how-audio-designers-are-redefining-digital-experiences/)
- [WCAG 1.3.3: Sensory Characteristics](https://wcag.dock.codes/documentation/wcag133/)
- [Smashing Magazine: Guidelines for Designing with Audio](https://www.smashingmagazine.com/2012/09/guidelines-for-designing-with-audio/)
- [WAI: Auditory Disabilities](https://www.w3.org/WAI/people-use-web/abilities-barriers/auditory/)
- [Windows 11 Sound Effects: Personalize Your Experience](https://reelmind.ai/blog/windows-11-sound-effects-personalize-your-experience/)
- [Custom Audio on Toast Notifications - Microsoft Learn](https://learn.microsoft.com/en-us/windows/apps/develop/notifications/app-notifications/custom-audio-on-toasts)
