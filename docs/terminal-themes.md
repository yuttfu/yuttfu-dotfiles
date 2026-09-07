# 终端主题

提供八套暗色主题，统一 Ghostty、Starship、fzf、SketchyBar、JankyBorders、独立日历与 Obsidian 配色。AeroSpace 工作区机制保持现状。

## 切换

点击 SketchyBar 右侧 **◈ 当前主题**，展开列表选择主题。菜单显示各主题的强调色色块和当前选中项，选中当前项不会重复执行；切换时显示进度与失败反馈。SketchyBar 通过事件局部换色，保留原有组件、CPU/内存曲线和采样节奏；Borders 即时换色；Ghostty 需要下面的重载快捷键，日历在关闭后下一次打开时更新。

```sh
terminal-theme --list
terminal-theme --current
terminal-theme jellyfish
terminal-theme aurora-x
terminal-theme poimandres
terminal-theme mocha-teal
```

选择后，在 Ghostty 按 **Command + Shift + 逗号**重新加载颜色。无需退出 shell，已运行的进程继续保留。终端中的既有输出若使用 ANSI 调色板会跟随改变；应用自己绘制的真彩色内容由该应用控制。

首次安装后，新开一个 Ghostty 标签页即可使用完整新配置。日后只切配色时，重新加载 Ghostty 即可。

支持八套暗色适配：`jellyfish`、`aurora-x`、`poimandres`、`mocha-teal`、`outrun-night`、`synthwave`、`dark-matter`、`amethyst-dark`。

## 唯一色板来源

`zsh/.config/terminal-themes/palettes.json` 保存每个主题的来源、适配说明、背景、文字、光标、选区与完整的 16 色 ANSI 调色板。

`terminal-theme` 从色板生成以下配置，并同步已登记 Obsidian Vault 的配色片段：

- `ghostty/.config/ghostty/themes/terminal-current`
- `sketchybar/.config/sketchybar/desktop-theme.lua`
- `borders/.config/borders/theme-colors.sh`
- `zsh/.config/terminal-themes/calendar.json`

主题切换只写颜色，不改字体、透明度或快捷键。它先检查全部输出的托管标记，再逐文件原子替换；写入失败时回滚已完成的文件，保留 Stow 链接。全部保存后才刷新桌面。`--no-refresh` 只生成文件，用于检查和离线部署。桌面文字采用中性亮色，强调色来自 ANSI 青色或各主题的 `desktop_accent`。窗口使用 10px 圆角边框，未激活窗口也使用不透明的低亮度边框。

日历 app 更新后首次使用需退出旧进程再打开；以后只切配色不用重启日历。打开中的事件编辑界面会保留当前配色，关闭后再打开才切换。

原始 VS Code 主题不一定提供完整终端色板，因此这些是基于原主题的终端适配，不是官方移植版。JellyFish 保留 `#00002c` 编辑器底色、`#ff92a5` 终端文字及 `#00f7ff` 光标色；ANSI 缺项从其语法/UI 色补齐。ANSI 红、绿保留错误/成功含义。Synthwave 只迁移颜色，不加入发光 CSS。

## 各 Profile 的独立性

Ghostty 的完整 Starship 显示系统、用户名、主机名、完整目录、Shell 和时间；Git、语言环境、超过两秒的命令耗时、非零退出码、后台任务按实际情况出现。它仍使用两行结构，第二行的 `❯` 是输入位置；家目录以 `~` 表示。VS Code 保留紧凑布局。两者使用终端 ANSI 颜色，不写固定十六进制配色。fzf 与补全提示也遵循终端色板。因此：

- Ghostty 使用 `terminal-theme` 选中的颜色。
- VS Code 集成终端使用当前 Profile 的主题颜色；切换 Ghostty 主题不会修改 VS Code Profile。
- 配色脚本不修改 VS Code 的设置、扩展或 Profile 关联。

Mac 与 Windows 的终端配色可以使用同一套 ANSI 设计，但这个切换脚本当前是 macOS/Linux 的本地文件工具，不直接配置 Windows Terminal。

## 电池模块

电量使用 62×24px 的紧凑胶囊，主题按钮使用 96×26px 胶囊。两者均设置外层整体居中，图标和文字在框内作为一组排列。显示随电量变化的电池图标与百分比。实际 `charging` 才显示充电图标；`charged` 且 100% 显示充满状态，`not charging` 或低于 100% 的 `charged` 显示接电暂停充电。点击可查看状态与系统提供的预计时间。不能仅根据 `AC Power` 判断正在充电。

## Obsidian 配色

当前接入 ACM Vault，保留 AnuPpuccin 的布局、字体和 Style Settings。深色模式下启用 `desktop-current` CSS 片段，点击 SketchyBar 主题按钮即可同步背景、正文、强调色、代码高亮和主题原有的彩色文件夹。Obsidian 监听 CSS 文件变动并自动应用，无需安装新插件。

`zsh/.config/terminal-themes/obsidian.py` 负责配色映射，`obsidian-vaults.json` 明确列出接入的 Vault 路径（支持 `~/`）；脚本只写各 Vault 的 `.obsidian/snippets/desktop-current.css`，不会每次切换都改外观设置。增加其他 Vault 时，在清单加入路径并在该 Vault 中启用同名片段。未挂载的 Vault 会提示并跳过；其他主题输出照常更新。

原有 `extended-colorschemes` 及 Style Settings 保留。片段通过主题色变量覆盖 Rose Pine 和红色强调色，关闭 `desktop-current` 即可恢复原来配色；浅色模式保持原样。首次使用时，在 Obsidian 外观设置中手动启用该片段。

## Codex 配色

八套适配导入文件和操作说明见 [Codex 配色](codex-themes.md)。运行 `terminal-theme jellyfish --codex` 只输出对应的导入文本，不改变当前桌面或 Codex 设置。

## 原生桌面滑动

见 [Spaces 与 AeroSpace 的使用边界](native-spaces.md)。仓库工作区按钮使用 AeroSpace 的模拟工作区。
