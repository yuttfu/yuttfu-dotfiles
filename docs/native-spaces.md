# 原生 Spaces 滑动与 AeroSpace

macOS 原生 Spaces 提供整组窗口横向滑动的桌面切换动画，可通过键盘或触控板手势触发。它与 AeroSpace 的模拟工作区使用不同机制。

## 先试效果

1. 从 AeroSpace 菜单退出 AeroSpace。它会把隐藏工作区的窗口移回可见区域，所以多个工作区窗口会暂时堆在一起；退出不会关闭这些应用。
2. 按 `Control + ↑` 进入调度中心，将鼠标移到顶部，点 `+` 新建“桌面 2”。
3. 在调度中心把几扇窗口拖到“桌面 2”，让两个桌面各有一组窗口。
4. 回到桌面，按 `Control + →` 切到右侧桌面，按 `Control + ←` 返回。也可以在触控板上用三指或四指左右轻扫（取决于系统设置的手势）。这一步才会产生整组桌面滑动。
5. 若手势没开启：系统设置 → 触控板 → 更多手势 → 在全屏幕应用程序之间轻扫。若动画只淡入淡出，检查辅助功能 → 显示 → 减弱动态效果。

回到 AeroSpace 工作流：在调度中心关闭试验新增的普通桌面，把窗口合并回每个显示器一个桌面，再启动 AeroSpace。恢复窗口归属和排列可能需要手动调整；旧配置文件与快捷键仍在。

## 现有配置如何对应

| 当前操作 | 实际作用 | 原生滑动 |
|---|---|---|
| `Option + 1…9` | 切 AeroSpace 模拟工作区 | 无 |
| SketchyBar 的工作区数字 | 调用 AeroSpace workspace | 无 |
| `Option + h/j/k/l` | 当前布局内切换窗口焦点 | 无 |
| `Option + r` | AeroSpace 内铺满窗口 | 不创建原生全屏 Space |
| `Control + ←/→` / 触控板轻扫 | 切 macOS 原生 Space | 有，前提是存在相邻 Space |

AeroSpace 通过把非当前工作区的窗口移出屏幕模拟工作区。官方预期用法是每个显示器一个原生 Space，不再混用系统 Spaces。因此不能把它的工作区按钮简单绑定到系统切换，同时声称布局、窗口归属和焦点都保持兼容；换快捷键也不会让 AeroSpace 的工作区自动获得系统动画。

长期以滑动为优先时，需要改为原生 Spaces 管桌面，并另选每个桌面的窗口排列方式。SketchyBar 的颜色、时钟、电量、日历与 Borders 可继续保留，但顶部工作区模块需要改接原生 Spaces 数据源。仓库当前仍使用 AeroSpace 工作区。

如果保留 AeroSpace 的自动平铺和现有工作区规则，则继续使用当前无滑动的工作区切换。机器配置不是这个差异的决定因素。

官方依据：[Apple：多个空间](https://support.apple.com/zh-cn/guide/mac-help/mh14112/mac)、[AeroSpace：模拟工作区机制](https://nikitabobko.github.io/AeroSpace/guide#emulation-of-virtual-workspaces)。
