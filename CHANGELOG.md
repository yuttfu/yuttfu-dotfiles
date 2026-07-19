# Changelog

## [2026-07-19]

### Added

- 加入用于新 Mac 迁移的 `bootstrap.sh`、最小 `Brewfile` 与 Stow 链接流程。
- 纳入 AeroSpace、SketchyBar、JankyBorders、Ghostty 和 Visual Studio Code 的已验证配置。
- 为 Visual Studio Code 记录 Vibrancy Continued 扩展恢复流程，并将应用资源修改保留为显式手动步骤。
- 加入 `macos/power.sh`，以可预览的方式恢复电源管理档位。
- 加入 Codex 守护工具 `codex-awake`：默认防止系统睡眠三小时，按需才保持显示器常亮。
- 加入迁移契约测试，覆盖冲突检测、链接幂等性、依赖恢复与命令行为。

### Changed

- AeroSpace 的终端规则改为 Ghostty，窗口位置与当前日常终端一致。
- 根目录忽略未整理的 Neovim、Yazi、WezTerm 和备用 AeroSpace 配置，避免它们意外进入发布内容。
- VS Code 改用 Catppuccin Mocha 与 Mauve 强调色，移除手写的深玫瑰覆盖，同时保留 macOS 透明效果。

### Intentionally not included

- Neovim、Yazi 与 WezTerm 暂不随此版本迁移；它们保留给后续单独学习和整理。
- 个人 shell 配置不在此仓库内，以避免把本机凭据或机器相关状态带入版本控制。
