# Google Chrome 配色

Chrome 使用官方 **Catppuccin Chrome Theme - Mocha**，与 SketchyBar、Ghostty 和 Visual Studio Code 共用同一套 Catppuccin Mocha 色板。这里不追求透明效果，也不引入自定义新标签页扩展。

## 安装

1. 在 Google Chrome 中打开 [Catppuccin Chrome Theme - Mocha](https://chromewebstore.google.com/detail/catppuccin-chrome-theme-m/bkkmolkhemgaeaeggcmfbghljjjoofoh)。
2. 点击 **添加至 Chrome**，确认应用主题。
3. 如果标签栏没有立即刷新，完全退出 Chrome 后重新打开。

官方主题 ID：

```text
bkkmolkhemgaeaeggcmfbghljjjoofoh
```

## 迁移与隐私

新 Mac 执行完仓库的基础恢复后，再按照上面的链接安装主题即可。不要复制整个 Chrome Profile；其中可能包含 Cookie、登录状态、历史记录、扩展数据和设备相关设置，不适合进入 dotfiles。

本仓库只记录可公开、可复现的主题来源，不自动修改 Chrome 的内部 `Preferences` 文件。这样可以避免 Chrome 更新、账号同步或 Profile 路径变化造成配置损坏。

## 恢复默认外观

打开 Chrome **设置 → 外观 → 重置为默认主题**。
