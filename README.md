# Chrono Calendar (曜日日历)

一款现代化的 Flutter 日历应用，集成 AI 智能功能，支持 Android 和 iOS 平台。

## 功能特性

### 日历管理
- 多视图切换：月视图、周视图、日视图
- 多日历支持：创建和管理多个日历，自定义颜色
- 事件管理：创建、编辑、删除日程事件
- 重复事件：支持 RFC 5545 标准的重复规则（每天、每周、每月、每年等）
- 事件提醒：本地通知提醒，支持多个提醒时间

### AI 智能创建
- 自然语言输入：用 AI 解析自然语言创建日程
- 多模型支持：
  - OpenAI (GPT-4, GPT-3.5)
  - DeepSeek
  - 通义千问 (Qwen)
  - Ollama (本地部署)

### 农历功能
- 农历日期显示
- 传统节日标注
- 二十四节气

### 倒计时与纪念日
- 倒计时管理：重要日期倒计时
- 纪念日：记录和追踪重要纪念日
- 农历支持：支持农历日期的倒计时和纪念日

### 待办事项
- 任务管理：创建和管理待办事项
- 状态追踪：标记完成状态
- 优先级设置

### 天气集成
- 当日天气：显示当前位置天气信息
- 天气预报：未来几天天气预览
- 数据来源：Open-Meteo API

### 数据同步
- iCalendar 导入导出：支持 .ics 文件导入导出
- 网络订阅：订阅网络日历 (ICS URL)
- 智能去重：基于内容指纹识别重复事件

### 其他功能
- 事件搜索：快速搜索日程、倒计时、待办
- 事件分享：分享日程给他人
- 深色模式：支持浅色/深色主题切换
- 多语言：中文界面

## 截图

<!-- 添加应用截图 -->

## 安装

### 环境要求
- Flutter SDK >= 3.5.0
- Dart SDK >= 3.5.0
- Android SDK >= 21 (Android 5.0)
- iOS >= 12.0

### 构建步骤

```bash
# 克隆仓库
git clone https://github.com/your-username/chrono-calendar.git
cd chrono-calendar/chrono_calendar

# 安装依赖
flutter pub get

# 运行应用
flutter run

# 构建 Android APK
flutter build apk --release

# 构建 iOS (需要 macOS)
flutter build ios --release
```

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── app.dart               # MaterialApp 配置
├── core/
│   ├── constants/         # 常量定义
│   ├── theme/             # Material 3 主题
│   ├── router/            # 路由配置
│   └── utils/             # 工具类
├── data/
│   ├── models/            # 数据模型
│   └── repositories/      # 数据仓库
├── services/              # 业务服务
├── viewmodels/            # 视图模型 (MVVM)
└── views/
    ├── screens/           # 页面
    └── widgets/           # 组件
```

## 技术栈

- **框架**: Flutter 3.5+
- **架构**: MVVM + Provider
- **路由**: go_router
- **数据库**: SQLite (sqflite)
- **网络**: Dio
- **日历 UI**: table_calendar
- **农历**: lunar
- **通知**: flutter_local_notifications

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request。
