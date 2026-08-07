# Changelog

## [2026-08-07]

### Added

- SketchyBar 右侧加入日期时钟、CPU/RAM 合并指标和 OBS 录制状态；时钟与指标支持悬停展开。
- AeroSpace 加入 `Alt+R` 录制专注模式，全屏当前窗口并临时移除外边距，避免手风琴布局露出其他窗口。

### Changed

- 针对 MacBook 刘海屏停用中间音乐岛入口并保留 helper 源码，右侧状态区成为主要信息区域。

## [2026-08-05]

### Added

- 加入位于 SketchyBar 中间的音乐岛：封面与歌名紧凑显示、悬停展开歌手、新歌自动展开 5 秒。
- 加入原生 `yuttfu Media Helper` 面板，提供 QQ音乐进度、上一首/播放/下一首、最近 6 首记录与语义搜索回放。
- 加入 QQ音乐只读队列解析、封面缓存、自定义 SketchyBar 事件和登录启动项；网易云音乐保留系统媒体信息的尽力而为支持。
- 加入 15 项 Swift 核心测试（含显式启用的 QQ音乐真实归档兼容测试）以及迁移、Lua 语法和音乐岛契约测试。

### Security

- QQ音乐控制只使用辅助功能角色与文本语义，不写死屏幕坐标，不修改 QQ音乐私有文件，也不提交播放历史和封面缓存。

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
