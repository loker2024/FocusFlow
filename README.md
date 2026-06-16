# FocusFlow

FocusFlow 是一个 macOS SwiftUI 效率工具，把番茄钟、时间追踪、任务管理、工作日志、习惯打卡、目标追踪和倒数日放在一个轻量桌面应用里。数据通过 `UserDefaults` 存在本地，不需要账号或后端服务。

## 功能

- 番茄钟：自定义时长、进度环、暂停/重置、今日专注统计。
- 时间追踪：类别、项目备注、实时计时、历史记录、今日分类统计。
- 任务管理：搜索、状态筛选、优先级、完成状态、菜单栏快速添加任务。
- 工作日志：心情、生产力评分、按日期编辑、历史记录。
- 习惯打卡：每日打卡、完成统计、连续天数计算。
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

## 验证

仓库包含一个轻量 Swift 检查脚本，用于验证模型和数据存储逻辑。它不依赖 XCTest，适合只安装 Command Line Tools 的环境。

```bash
swiftc -parse-as-library \
  FocusFlow/Models/Models.swift \
  FocusFlow/Services/DataStore.swift \
  Scripts/check_focusflow.swift \
  -o /tmp/focusflow-checks

/tmp/focusflow-checks
```

预期输出：

```text
All FocusFlow checks passed.
```

## 项目结构

```text
FocusFlow/
  FocusFlowApp.swift          应用入口和菜单栏配置
  Models/Models.swift         Codable 数据模型和日期辅助逻辑
  Services/DataStore.swift    本地持久化和数据操作
  Views/                      SwiftUI 功能视图
Scripts/
  check_focusflow.swift       轻量模型/数据验证脚本
```
