# Android / Trime 主题

[`kongshan_keytao.trime.yaml`](kongshan_keytao.trime.yaml) 是按目标截图适配的 **26 键**主题成品，可直接导入 Trime，无需 Jsonnet、图片或额外字体。配置以 Trime 3.3.12 为参考；旧版工具栏格式不同，建议升级后使用。

## 安装

1. 在手机 Trime 设置中确认「用户资料夹」的位置，将 `kongshan_keytao.trime.yaml` 放入该目录的**根目录**，不要放在 `extra/` 或 `build/` 内。若用户资料夹为 `/storage/emulated/0/rime`，目标路径即 `/storage/emulated/0/rime/kongshan_keytao.trime.yaml`。
2. 执行「部署」，在「主题」中选择「空山键道 26 键」。如需选择配色，选「空山深色」。修改主题后重新部署并重新选择主题以刷新。
3. 在「方案」中启用你自己的 KeyTao 方案。主题只定义键盘，不附带词库、Lua 或输入方案，也不会替你配置它们。
4. 关闭「隐藏按键符号」和「隐藏按键助记」，才能同时显示键帽上的两层小字。

## 外观和操作

- 深色底板、灰色圆角键、白字，Q/F 绿色、W/J 橙色、U/I/O/A/V 青色、X 红色、回车绿色。
- 第一排上划输入 1–0；其他上划符号与 `jsonnet/Buttons/Layout26.libsonnet` 一致。
- 下划 A 全选、Z 撤销、X 剪切、C 复制、V 粘贴；Z/X/C/V 也支持长按。其他下划符号显示在键帽的第二层小字上。
- Shift 切换大小写，长按用于锁定；有待上屏编码时，点击改为输入 `;`，配合本仓库键道长词组查询。
- 左下角 `#` 点击打开截图中的数字／符号页：第一排 `1–0`，第二排 `- / : ; ( ) ¥ @ “ ”`，第三排 `#+=`、`+ * 、 # ? ! .` 和退格，底排为绿色返回箭头、`。`、空格、`=` 和回车。
- `#+=` 打开原有中文标点页，该页的 `#` 返回数字／符号页。绿色 `←` 返回主键盘；其他页面用 `ABC` 返回。主键盘左下角上划/长按仍打开独立数字键盘，下划打开表情。
- 空格显示当前方案名称，不写死为“键道 6”；长按中英切换键打开方案菜单。
- 回车根据编辑框显示“搜索／发送／完成”等；普通编辑框显示“回车”，不会强制执行搜索。
- 顶栏为方案菜单、符号、表情、剪贴板和收起；输入过程中由 Trime 切换为候选栏。编辑快捷键的实际支持取决于目标应用。

## 微调与边界

直接修改主题文件后重新部署，不运行元书的 `main.jsonnet`：两者是独立的主题格式，现有元书源码和产物保持不变。

| 位置 | 用途 |
| --- | --- |
| `style/keyboard_height`、`keyboard_height_land` | 竖屏、横屏键盘高度，当前均为 220，保持两层提示的间距 |
| `style/horizontal_gap`、`vertical_gap`、`round_corner` | 键间距和圆角 |
| `preset_color_schemes/kongshan` | 键盘背景、普通键及各彩色键的颜色 |
| `preset_keyboards/default` | 主键盘布局、手势、提示位置；两层小字分别使用 `label_symbol` 和 `hint` |

这是截图中**未输入时的符号提示版**，不是 17 键，也没有实现元书输入过程中动态替换成声韵/笔画助记的通知逻辑。Android 不复刻 iOS 的底部地球键、麦克风、透明磨砂和系统栏；布局尺寸及字体渲染仍需在实际手机上微调。

参考：[Trime 默认主题（v3.3.12）](https://github.com/osfans/trime/blob/v3.3.12/app/src/main/assets/shared/trime.yaml)、[主题配置文档](https://github.com/osfans/trime/wiki/Theme-Configuration-%28New%29)。
