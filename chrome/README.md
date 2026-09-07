# Google Chrome 配色

八套本地原生主题保存在 `chrome/themes/`，从 `zsh/.config/terminal-themes/palettes.json` 生成，与终端、SketchyBar、Borders、Obsidian 和日历共用色板。Chrome 使用手动加载，不跟随 SketchyBar 自动切换。

## 手动安装与切换

1. 进入你想配置的 Chrome Profile，在地址栏输入 `chrome://extensions`。
2. 开启右上角 **开发者模式**。
3. 点击 **加载未打包的扩展程序**，选择某套主题文件夹。选择的是文件夹，不是里面的 `manifest.json`。
4. macOS 选择文件夹时按 `Command + Shift + G`，粘贴路径后回车，再点击“选择”。
5. 安装成功后，关闭顶部“已安装主题背景”的提示条（点关闭，不是“撤销”），方便之后切回之前用过的主题。

首次使用 JellyFish：

```text
~/dotfiles/chrome/themes/jellyfish
```

以后换主题时重复第 3–4 步，选择下表对应目录；不用先重置原主题。Chrome 可能清理闲置主题，因此不依赖它保存所有旧主题。主题目录放在 dotfiles 固定位置，请勿移动到临时目录。

| 配色 | themes 下的目录 |
|---|---|
| JellyFish | `jellyfish` |
| Aurora X | `aurora-x` |
| poimandres | `poimandres` |
| Catppuccin Mocha / Teal | `mocha-teal` |
| Outrun Night | `outrun-night` |
| Synthwave x Fluoromachine | `synthwave` |
| Workbench / Dark Matter | `dark-matter` |
| Amethyst Dark | `amethyst-dark` |

主题控制标签栏、工具栏、地址栏、书签文字和新标签页配色。普通网站正文仍由网站自身主题控制；保留 Chrome 自带新标签页，没有替换新标签页的扩展。

## 色板更新

修改共享色板后，重新生成八套主题包：

```sh
python3 ~/dotfiles/chrome/generate-themes.py
```

然后在 Chrome 重新加载所需主题目录。生成器不操作 Chrome，也不改变当前桌面配色。现有生成文件没有变化时不会重写；遇到同名非托管 manifest 会停止，避免覆盖个人文件。

## Profile、迁移与恢复

在目标 Chrome Profile 内加载主题，其他 Profile 需要分别操作。Chrome 账号同步设置可能影响主题同步；本地主题目录仍需在新电脑上从 dotfiles 恢复，不复制整个 Chrome Profile、Cookie、历史记录或扩展私有数据。

仓库中的每个主题只保存声明颜色的 `manifest.json`，不包含 JavaScript、网页访问权限、后台进程或网络请求。这个仓库不修改 Chrome 内部的 `Preferences` 文件。

恢复 Chrome 默认外观：打开 `chrome://settings/appearance`，点击 **重置为默认主题背景**。

先前使用的官方 Catppuccin Mocha 主题仍可从 [Chrome 应用商店](https://chromewebstore.google.com/detail/catppuccin-chrome-theme-m/bkkmolkhemgaeaeggcmfbghljjjoofoh) 重新安装。

参考：[Chrome 官方主题格式](https://developer.chrome.com/docs/extensions/develop/ui/themes)。这些是个人配色适配，不是八款 VS Code 主题作者发布的 Chrome 官方移植。

## 切换未生效时

若加载旧主题后颜色没有改变，先关闭之前的安装提示，或离开扩展页面再返回，再加载一次。安装提示仍保留“撤销”时，Chrome 可能保留旧主题为停用状态，单纯重载它不会重新启用。

Chrome 会在已加载目录生成 `Cached Theme.pak` 缓存；`chrome/.gitignore` 排除此文件，保留本地缓存，不把它作为配色源提交。
