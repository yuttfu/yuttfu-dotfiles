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
bash tests/test_glass_effects.sh
bash tests/test_bootstrap.sh
```
