# Codex 配色

八套深色界面适配由 `zsh/.config/terminal-themes/palettes.json` 生成，使用 Codex 的 `codex-theme-v1:` 分享格式。背景、正文、强调色以及新增/删除/技能颜色均取自同一色板。

## 使用

1. 打开顶部主题菜单，点击 **复制 Codex 当前配色**。显示“已复制”后，当前桌面主题的导入文本就在剪贴板中；也可以运行 `terminal-theme --copy-codex`。
2. 在 Codex 按 `⌘,` 打开设置，进入 **Appearance**。
3. 选择 **Dark** 模式，在 **Dark theme → Import** 中粘贴并导入。
4. 换另一套时，同样导入对应文件。导入会覆盖当前深色主题设置；需要保留旧设置时可先用 Copy theme 复制保存。

不需要先装 VS Code 扩展或自己配置基础主题。导入文本只包含外观参数，不包含账户信息。

| 方案／导入文件 | 背景 | 正文 | 强调色 | 代码高亮搭配 |
|---|---|---|---|---|
| [JellyFish](codex-themes/jellyfish.txt) | `#00002c` | `#ffffff` | `#00d9ff` | `dracula` |
| [Aurora X](codex-themes/aurora-x.txt) | `#07090f` | `#eeffff` | `#86a5ff` | `tokyo-night` |
| [poimandres](codex-themes/poimandres.txt) | `#1b1e28` | `#e4f0fb` | `#5de4c7` | `nord` |
| [Catppuccin Mocha / Teal](codex-themes/mocha-teal.txt) | `#1e1e2e` | `#cdd6f4` | `#94e2d5` | `catppuccin` |
| [Outrun Night](codex-themes/outrun-night.txt) | `#161130` | `#ffffff` | `#42c6ff` | `dracula` |
| [Synthwave x Fluoromachine](codex-themes/synthwave.txt) | `#200933` | `#ffffff` | `#fc199a` | `dracula` |
| [Workbench / Dark Matter](codex-themes/dark-matter.txt) | `#001928` | `#ffffff` | `#00e1ff` | `vscode-plus` |
| [Amethyst Dark](codex-themes/amethyst-dark.txt) | `#120024` | `#f2e8f7` | `#ba7dd9` | `dracula` |

共通设置：Contrast 60、半透明侧栏、UI 使用系统字体、代码使用 MesloLGS NF。正文选择中性亮色，避免整段聊天文字都呈粉色。可以在 Codex 里自行改字体而不影响其他软件。

## 适配边界

界面色由这套配置控制；代码语法高亮使用 Codex 内置的相近主题，因此不是八款 VS Code 扩展逐个 token 的完整移植。选择内置代码主题可能同时重置界面配色，要恢复整套适配请重新导入。

顶部主题按钮目前同步 SketchyBar、Borders、Ghostty 配置、日历、已接入的 Obsidian Vault 与 VS Code 共享主题；不会自动更改 Codex 当前设置。`terminal-theme <ID> --codex` 随时从唯一色板生成最新导入文本，不修改任何应用或系统剪贴板。只有点击复制菜单项或执行 `--copy-codex` 才写入剪贴板；普通主题切换不改剪贴板。复制会先验证并生成完整文本，失败时显示错误，不把空导出作为成功。

官方功能说明：[Appearance 设置](https://learn.chatgpt.com/docs/reference/settings#appearance)。

## 自动切换的范围

Codex 的 System 模式跟随系统深浅模式，不会跟随 SketchyBar 的八套色板。本配置通过 Import 手动切换 Codex 自定义主题。
