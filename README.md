# FocusFlow

FocusFlow 是一个 macOS SwiftUI 效率工具，把专注训练、待办、工作日志、目标追踪和倒数日放在一个轻量桌面应用里。数据通过 `UserDefaults` 存在本地，不需要账号或后端服务。

## 功能

- 专注训练：支持正向累计和反向倒计时；反向可选快捷时长或自定义分钟，并可关联待办。
- 待办：用待办组分类，支持搜索、状态筛选、优先级、删除和菜单栏快速添加；点击待办可查看专注次数与累计时长。
- 每日复盘：心情、生产力评分、按日期编辑、专注时长扇形图和历史记录。
- 目标追踪：目标日期、手动进度、里程碑、里程碑完成后自动更新进度。
- 倒数日：一次性或每年重复事件、排序、颜色、菜单栏预览。
- 菜单栏：快速入口、今日统计、即将到来的事件、打开主窗口。

## 环境要求

- macOS 14 或更高版本
- Swift 5.9 或更高版本

## 运行

```bash
swift build
swift run FocusFlow
```

## 打包

生成应用图标和桌面安装包：

```bash
python3 Scripts/generate_app_icon.py
Scripts/package_dmg.sh
```

重新生成图标需要 Python Pillow 和 macOS 自带的 `iconutil`。打包完成后会在桌面生成 `FocusFlow.app` 和 `FocusFlow.dmg`。旧入口 `build_app.sh` 会转调同一个打包脚本，避免应用元信息、图标和签名流程不一致。

## 验证

仓库包含一个轻量 Swift 检查脚本，用于验证模型和数据存储逻辑。它不依赖 XCTest，适合只安装 Command Line Tools 的环境。

```bash
swiftc -parse-as-library \
  FocusFlow/Models/Models.swift \
  FocusFlow/Services/DataStore.swift \
  FocusFlow/Services/TimerControllers.swift \
  Scripts/check_focusflow.swift \
  -o /tmp/focusflow-checks

/tmp/focusflow-checks
```

预期输出：

```text
All FocusFlow checks passed.
```

GitHub Actions 会在 `main` 分支 push 和 pull request 时自动执行 `swift build` 与上述轻量检查。

## 项目结构

```text
FocusFlow/
  FocusFlowApp.swift          应用入口和菜单栏配置
  Models/Models.swift         Codable 数据模型和日期辅助逻辑
  Resources/                  应用图标资源
  Services/DataStore.swift    本地持久化和数据操作
  Views/                      SwiftUI 功能视图
Scripts/
  generate_app_icon.py        可复现的应用图标生成脚本
  package_dmg.sh              生成桌面 .app 和 .dmg
  check_focusflow.swift       轻量模型/数据验证脚本
```
