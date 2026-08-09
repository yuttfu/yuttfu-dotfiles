# Changelog

## [2026-08-09]

### Added

- SketchyBar 右侧加入固定宽度的 `FOCUS HH:MM:SS` 学习计时器，以及独立的 CPU/RAM 百分比和微型曲线。
- 日期与等宽时钟拆分成稳定的时间组；点击日期会打开无 Dock 图标的本地原生月历。
- 原生日历提供 7×6 月视图、月份导航和返回今天；每天支持多条可选时间事件，有事件的日期统一显示红点，点击日期后在月历上方打开当天事件浮层。
- bootstrap 会按需构建 `$HOME/Applications/yuttfu Calendar.app`，并增加 Lua、Swift Core、AppKit 契约和迁移测试。

### Changed

- 计时器不再悬停扩宽；主项目收紧至 150px 并明确左对齐，未开始、运行和暂停只改变状态点颜色，popup 保持 220px。
- CPU 与 RAM 继续共用一次系统采样，但使用两个独立固定宽度组件；正常状态降低边框对比度，达到阈值后才使用警告色。
- 电池正常状态改用中性细线图标，接电显示绿色闪电，低电量才显示红色告警。
- 刘海屏布局将常用信息固定在两侧，中间区域保持干净，右侧学习仪表台成为主要信息区域。

### Fixed

- 日历面板使用 `orderFrontRegardless` 在当前 Space 展开，不再主动激活 accessory 应用并把用户切到桌面。
- 首次通过 URL 启动日历时会把 toggle 延迟到 AppKit 启动完成后的主队列，不再需要点击第二次。
- 日历 JSON 损坏时会保留带时间戳的备份并恢复为空数据，避免影响 SketchyBar。

### Privacy

- 日期事件只保存在 `$HOME/Library/Application Support/yuttfu-sketchybar/calendar-marks.json`；版本 1 分类备注会自动迁移为版本 2 全天事件，不调用 Apple Calendar、不创建 LaunchAgent，也不提交个人数据。

## [2026-08-07]

### Added

- SketchyBar 右侧加入日期时钟、CPU/RAM 合并指标和 OBS 录制状态；时钟与指标支持悬停展开。
- AeroSpace 加入 `Alt+R` 录制专注模式，全屏当前窗口并临时移除外边距，避免手风琴布局露出其他窗口。

## [2026-07-19]

### Added

- 加入用于新 Mac 迁移的 `bootstrap.sh`、最小 `Brewfile` 与 Stow 链接流程。
- 纳入 AeroSpace、SketchyBar、JankyBorders、Ghostty 和 Visual Studio Code 的已验证配置。
- 为 Visual Studio Code 记录 Vibrancy Continued 扩展恢复流程，并将应用资源修改保留为显式手动步骤。
- 加入 `macos/power.sh`，以可预览的方式恢复电源管理档位。
- 加入 Codex 守护工具 `codex-awake`：默认防止系统睡眠三小时，按需才保持显示器常亮。
- 加入迁移契约测试，覆盖冲突检测、链接幂等性、依赖恢复与命令行为。
- 加入 SketchyBar 专注信标：正计时、悬停精确读数、popup 开始/暂停/复位，以及睡眠自动暂停。

### Changed

- AeroSpace 的终端规则改为 Ghostty，窗口位置与当前日常终端一致。
- 根目录忽略未整理的 Neovim、Yazi、WezTerm 和备用 AeroSpace 配置，避免它们意外进入发布内容。
- VS Code 改用 Catppuccin Mocha 与 Mauve 强调色，移除手写的深玫瑰覆盖，同时保留 macOS 透明效果。
- 专注信标恢复为电量左侧的图标与分钟显示；popup 内的开始/暂停和复位改为纵向同宽、文字居中。

### Intentionally not included

- Neovim、Yazi 与 WezTerm 暂不随此版本迁移；它们保留给后续单独学习和整理。
- 个人 shell 配置不在此仓库内，以避免把本机凭据或机器相关状态带入版本控制。
