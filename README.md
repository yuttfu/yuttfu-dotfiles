# yuttfu dotfiles

一套可迁移的 macOS 桌面环境：AeroSpace 管理窗口，SketchyBar 负责顶部状态栏，JankyBorders 标出当前窗口；Ghostty 和 Visual Studio Code 使用克制的玻璃透明效果。

它只包含已经整理、验证过的配置。Neovim、Yazi、WezTerm 和个人 shell 配置仍留在工作目录中，不会随这次迁移安装或覆盖。

## 在新 Mac 上恢复

1. 先安装 Xcode Command Line Tools 和 [Homebrew](https://brew.sh/)，然后克隆这个仓库。
2. 进入仓库，先做只读检查：

   ```bash
   ./bootstrap.sh --check
   ```

3. 检查通过后，安装依赖、创建配置链接，并恢复已记录的 VS Code 扩展：

   ```bash
   ./bootstrap.sh --apply
   ```

   安装脚本会在发现已有的用户配置与本仓库冲突时停止，不会覆盖它。若只想创建链接、且不安装 Homebrew 软件包和扩展，可使用：

   ```bash
   ./bootstrap.sh --apply --links-only
   ```

4. 首次启动 AeroSpace、SketchyBar 和 JankyBorders 时，按 macOS 的提示授予所需权限；AeroSpace 通常需要辅助功能权限。

## SketchyBar 学习仪表台

右侧状态区以学习计时为主：150px 的 `FOCUS HH:MM:SS` 使用明确左对齐，点击后可以开始、暂停和复位；CPU 与 RAM 分开显示图标、百分比和短曲线；电池在正常状态使用中性细线图标，接电时才显示绿色闪电；日期与等宽时钟组成一个安静的时间组。刘海屏布局不会加载中间音乐岛，避免组件被摄像头区域遮挡。

点击日期会打开无 Dock 图标的本地月历。月历提供固定 7×6 日期网格；有事件的日期显示红点，点击某天后会在月历上方打开当天事件浮层。每天可以保存多条“可选时间 + 标题”事件，并逐条删除。旧版分类备注会在内存中自动迁移成全天事件，下一次写入时保存为版本 2。它不调用 Apple Calendar，也不请求日历权限；数据只保存在：

```text
$HOME/Library/Application Support/yuttfu-sketchybar/calendar-marks.json
```

完整的 `./bootstrap.sh --apply` 会构建并安装 `$HOME/Applications/yuttfu Calendar.app`；`--links-only` 不会触发 Swift 构建。修改日历源码后也可以单独重建：

```bash
bash macos/yuttfu-calendar-panel/build-app.sh "$HOME/Applications/yuttfu Calendar.app"
```

## SketchyBar 音乐岛

音乐岛位于 SketchyBar 中间：新歌会展开 5 秒，悬停时显示歌手，点击后打开带进度、播放控制和最近 6 首记录的原生面板。QQ音乐是完整适配目标；网易云音乐使用系统媒体信息，属于尽力而为支持。

`./bootstrap.sh --apply` 会构建 `$HOME/Applications/yuttfu Media Helper.app` 并安装登录启动项。第一次安装后可以直接启动：

```bash
open -g "$HOME/Applications/yuttfu Media Helper.app"
```

随后在“系统设置 → 隐私与安全性 → 辅助功能”中允许 **yuttfu Media Helper**。这项权限只用于读取 QQ音乐的播放状态、操作上一首/播放/下一首、拖动进度，以及按歌名与歌手定位历史歌曲；不会写入 QQ音乐的数据文件，也不会使用固定屏幕坐标。

修改 helper 后可单独重建：

```bash
bash macos/yuttfu-media-helper/build-app.sh "$HOME/Applications/yuttfu Media Helper.app"
```

运行时只会在 `$HOME/.cache/yuttfu-sketchybar/` 保存最近 6 首记录和 QQ音乐封面缓存，这些内容不会进入 Git。若 QQ音乐升级后控制失效，先确认辅助功能权限仍然开启，再运行下面的核心测试并检查 `PlayingList.archive` 字段或辅助功能元素是否变化。

## 防止 Codex 工作时过快睡眠

下面的电源档位已经按这台 Mac 的使用方式设计：接电时关闭系统自动睡眠但保留 30 分钟熄屏；电池时 10 分钟熄屏、15 分钟睡眠。先查看当前值：

```bash
./macos/power.sh --check
```

先预览会执行的管理员命令：

```bash
./macos/power.sh --apply --dry-run
```

确认后再真正应用：

```bash
./macos/power.sh --apply
```

日常只希望 Codex 不中断，可以临时保持系统唤醒三个小时：

```bash
codex-awake --minutes 180
```

`bootstrap.sh` 会把这个工具链接到 `$HOME/.local/bin/codex-awake`。如果你的 shell 尚未把该目录放入 `PATH`，请直接运行 `$HOME/.local/bin/codex-awake --minutes 180`，或自行将该目录加入 shell 的 `PATH`。需要同时阻止显示器熄屏时，额外传入 `--display`；合盖和手动睡眠仍然有效。

## Ghostty 与 Visual Studio Code 透明效果

Ghostty 的主题、字体和透明度由仓库中的配置直接控制。Visual Studio Code 使用与 Ghostty 一致的 Catppuccin Mocha（Mauve 强调色与 minimal 工作台），设置文件会被链接，扩展清单会在 `./bootstrap.sh --apply` 时恢复。

由于它会改动 VS Code 的应用资源，玻璃效果必须在 VS Code 内手动确认：安装完成后打开命令面板，运行 **Vibrancy Continued: Enable Vibrancy**。VS Code 更新后若效果失效，再运行 **Vibrancy Continued: Reload Vibrancy**。这是刻意保留的显式操作，避免迁移脚本静默修改应用包。

## 本地验证

```bash
bash tests/test_desktop_shell.sh
bash tests/test_status_widgets.sh
bash tests/test_calendar_panel.sh
bash tests/test_glass_effects.sh
bash tests/test_bootstrap.sh
bash macos/yuttfu-calendar-panel/test-core.sh
bash macos/yuttfu-media-helper/test-core.sh
```
