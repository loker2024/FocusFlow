# 2026-06-16

## 项目初始化
- 创建项目目录结构 ~/FocusFlow
- 设计项目架构：SwiftUI + UserDefaults
- 确定功能模块：番茄钟、时间追踪、任务管理、工作日志、打卡、目标追踪、倒数日
- 初始化 Git 仓库并创建 GitHub 仓库

## 数据模型层
- 创建 Models.swift，定义所有数据模型
  - PomodoroSession: 番茄钟会话
  - TimeEntry: 时间记录
  - TaskItem: 任务（支持优先级）
  - WorkLog: 工作日志
  - Habit: 习惯打卡
  - Goal: 目标追踪（含里程碑）
  - CountdownEvent: 倒数日

## 数据存储层
- 创建 DataStore.swift，实现 UserDefaults 持久化
- 实现各模块的 CRUD 操作
- 使用单例模式共享数据

## 主界面框架
- 创建 ContentView.swift，实现侧边栏导航
- 支持 7 个功能模块切换
- 使用 NavigationSplitView 布局

## 已完成的功能视图
- PomodoroView: 番茄钟（计时、暂停、重置、统计）
- TimeTrackerView: 时间追踪（计时、分类、历史记录）
- TaskListView: 任务管理（增删改查、搜索、过滤、优先级）
- WorkLogView: 工作日志（心情、生产力评分、历史）
- HabitView: 习惯打卡（打卡、连续天数、统计）
- GoalView: 目标追踪（进度、里程碑、倒计时）
- CountdownView: 倒数日（事件管理、倒计时、每年重复）
- MenuBarView: 菜单栏组件（快速操作、今日统计、即将到来事件）

## 项目配置
- 创建 Package.swift 用于 Swift Package Manager
- 创建 .gitignore 和 README.md

## Git 提交记录
1. 初始化项目：添加 .gitignore 和 README
2. 添加数据模型层
3. 添加数据存储层
4. 添加主应用入口和主视图框架
5. 添加番茄钟功能
6. 添加时间追踪功能
7. 添加任务管理功能
8. 添加工作日志功能
9. 添加习惯打卡功能
10. 添加目标追踪功能
11. 添加倒数日功能
12. 添加菜单栏组件
13. 添加项目配置和进度文档

## GitHub 仓库
- 地址：https://github.com/loker2024/FocusFlow
- 已推送 main 分支

## 已修复问题
- 修复番茄钟选择时长后时钟不更新的问题
- 修复键盘无法输入的问题（添加 @FocusState 焦点管理）

## 本轮打磨
- 提取倒数日年度重复、剩余天数和习惯连续天数逻辑，便于复用和验证
- 修复菜单栏打开主窗口、快速添加任务空白处理、当天倒数日遗漏等交互细节
- 工作日志支持按日期载入已有内容，保存后保留当前编辑状态
- 增加 `Scripts/check_focusflow.swift`，覆盖日期计算、习惯打卡、工作日志更新和数据持久化检查
- 完善 README，补充功能说明、运行命令、验证命令和项目结构
- 更新 `.gitignore`，忽略 SwiftPM 和 macOS 常见生成文件

## 待完成
- 应用图标和资源
- 接入标准单元测试框架或 CI（当前已有轻量检查脚本）
