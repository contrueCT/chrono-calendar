# Chrono 日历应用技术文档

> Chrono - 一款现代化 Flutter 日历应用，集成 AI 智能功能，支持 Android + iOS。

---

## 一、项目概述

### 1.1 项目信息

| 项目名称 | Chrono Calendar |
|---------|-----------------|
| 技术框架 | Flutter 3.24+ / Dart 3.5+ |
| 目标平台 | Android + iOS |
| 架构模式 | MVVM (Model-View-ViewModel) |
| 状态管理 | Provider |
| 数据存储 | SQLite (sqflite) |
| 路由方案 | go_router |

### 1.2 核心功能

- 日历视图（月/周/日）
- 日程管理（CRUD、重复事件、拖拽调整）
- 提醒通知
- iCalendar 导入导出
- 网络日历订阅
- 农历显示（节气、节日）
- 事件搜索
- AI 自然语言创建日程
- 倒计时/纪念日
- 天气集成
- 事件分享

---

## 二、技术选型

| 类别 | 技术 | 版本 | 说明 |
|------|------|------|------|
| 框架 | Flutter | 3.24+ | 跨平台 UI 框架 |
| 语言 | Dart | 3.5+ | 主要编程语言 |
| 状态管理 | Provider | 6.1.2 | 简洁高效的状态管理 |
| 数据库 | sqflite | 2.3.3+ | SQLite 本地存储 |
| 网络 | Dio | 5.7.0 | HTTP 客户端 |
| 路由 | go_router | 14.6.2 | 声明式路由 |
| 日历UI | table_calendar | 3.1.2 | 日历组件 |
| 时间处理 | intl | 0.19.0 | 国际化/日期格式化 |
| 农历 | lunar | 1.3.0 | 农历转换 |
| 通知 | flutter_local_notifications | 18.0.1 | 本地通知 |
| 安全存储 | flutter_secure_storage | 9.2.2 | API Key 安全存储 |

---

## 三、架构设计

### 3.1 MVVM 架构

```
┌─────────────────────────────────────────────────┐
│                    VIEW LAYER                   │
│  (Screens, Widgets) - UI 展示层                  │
└─────────────────────┬───────────────────────────┘
                      │ Consumer / Provider.of
                      ▼
┌─────────────────────────────────────────────────┐
│                 VIEWMODEL LAYER                 │
│  (ChangeNotifier) - 业务逻辑层                   │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│               REPOSITORY LAYER                  │
│  数据访问抽象层                                   │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              SERVICE / DATA LAYER               │
│  (DatabaseService, API Clients)                 │
└─────────────────────────────────────────────────┘
```

### 3.2 目录结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # MaterialApp 配置
├── core/                        # 核心模块
│   ├── constants/               # 常量定义
│   ├── theme/                   # 主题系统
│   ├── router/                  # 路由配置
│   ├── extensions/              # 扩展方法
│   └── utils/                   # 工具类
├── data/                        # 数据层
│   ├── models/                  # 数据模型
│   ├── repositories/            # 仓库层
│   └── datasources/             # 数据源
├── services/                    # 服务层
├── viewmodels/                  # ViewModel 层
└── views/                       # 视图层
    ├── screens/                 # 页面
    └── widgets/                 # 组件
```

---

## 四、核心数据结构

### 4.1 数据库表

| 表名 | 说明 |
|------|------|
| calendars | 日历表 |
| events | 事件表 |
| reminders | 提醒表 |
| event_cache | 事件缓存表（重复事件实例） |
| countdowns | 倒计时表 |
| search_history | 搜索历史表 |
| weather_cache | 天气缓存表 |
| llm_config | LLM 配置表 |

### 4.2 时间存储策略

- **数据库存储**: UTC 时间戳（毫秒）
- **内存表示**: DateTime（本地时区）
- **iCalendar 导出**: 带时区标识的时间

---

## 五、技术亮点及实现原理

### 5.1 主题系统

采用 Material Design 3 配色方案，支持亮色/深色/跟随系统三种模式：

- `ColorScheme` 定义完整的配色方案
- `ThemeData` 配置所有组件主题
- `SettingsViewModel` 持久化用户偏好

### 5.2 路由系统

使用 go_router 实现声明式路由：

- 路径常量集中管理
- 支持路径参数和查询参数
- 提供 BuildContext 扩展方法简化导航

### 5.3 数据库服务

单例模式的 SQLite 服务：

- 懒加载初始化
- 外键约束支持
- 通用 CRUD 方法封装
- 事务支持

---

## 六、遇到的问题与思考过程

### 问题 1: Material Design 3 主题系统的完整性设计

**问题描述**：
Material Design 3 引入了全新的 ColorScheme，包含近 30 个颜色属性。如何设计一个既完整又易于维护的主题系统？同时需要确保亮色和深色主题在视觉上保持一致性和协调性。

**思考过程**：
1. **颜色分层**：将颜色分为「基础色常量」和「主题配色方案」两层。`ColorConstants` 定义原子级颜色值，`AppColorSchemes` 组装成完整的 ColorScheme。
2. **语义化命名**：使用 `primaryLight/primaryDark` 这种命名方式，明确颜色的用途和主题归属。
3. **组件级主题**：在 `AppTheme` 中为每个 Material 组件（Button, Card, Input 等）单独配置样式，而不是依赖默认值，确保一致性。

**解决方案**：
采用三层架构：
- 第一层：`ColorConstants` - 定义所有颜色常量
- 第二层：`AppColorSchemes` - 组装 ColorScheme
- 第三层：`AppTheme` - 配置完整的 ThemeData

**关键代码**：
```dart
// 组件级主题配置示例 - 确保所有输入框样式一致
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: colorScheme.surfaceContainerHighest,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
    borderSide: BorderSide.none,
  ),
  // ... 配置所有状态的边框样式
),
```

---

### 问题 2: ViewModel 中异步初始化的处理

**问题描述**：
`SettingsViewModel` 需要在构造函数中从 SharedPreferences 加载用户设置。但 Dart 构造函数不能是异步的，如何优雅地处理这个初始化过程？

**思考过程**：
1. **方案一**：使用工厂构造函数 + 静态异步方法。但这会改变 ViewModel 的使用方式，与 Provider 的 `create` 参数不兼容。
2. **方案二**：在构造函数中调用异步方法，但不 await。存在 UI 先渲染默认值再刷新的问题。
3. **方案三**：添加 `isLoading` 状态，在异步加载完成前显示加载状态。

**解决方案**：
采用方案三，添加 `_isLoading` 状态字段：
- 初始值为 `true`
- 异步加载完成后设为 `false`
- UI 层可根据此状态显示骨架屏或加载指示器

**关键代码**：
```dart
class SettingsViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  SettingsViewModel() {
    _loadSettings(); // 构造函数中触发异步加载
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ... 加载设置
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

### 问题 3: 数据库外键约束与 SQLite 配置

**问题描述**：
SQLite 默认不启用外键约束，这意味着即使定义了 `FOREIGN KEY ... ON DELETE CASCADE`，删除父记录时子记录也不会自动删除。如何确保外键约束生效？

**思考过程**：
1. SQLite 外键约束需要通过 `PRAGMA foreign_keys = ON` 显式启用
2. 这个 PRAGMA 必须在每次数据库连接时执行
3. sqflite 提供了 `onConfigure` 回调，在数据库打开后、任何操作之前调用

**解决方案**：
在 `DatabaseService` 的 `openDatabase` 中使用 `onConfigure` 回调启用外键约束。

**关键代码**：
```dart
return await openDatabase(
  path,
  version: DbConstants.databaseVersion,
  onCreate: _onCreate,
  onUpgrade: _onUpgrade,
  onConfigure: _onConfigure, // 关键：配置外键约束
);

Future<void> _onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}
```

---

### 问题 4: 路由系统的可扩展性设计

**问题描述**：
应用有十多个页面，如何设计一个清晰、可维护、支持参数传递的路由系统？

**思考过程**：
1. **路径管理**：使用常量类集中管理路由路径，避免字符串硬编码
2. **参数传递**：go_router 支持路径参数（`:uid`）和查询参数（`?id=xxx`）
3. **导航便捷性**：为常用导航场景提供 BuildContext 扩展方法

**解决方案**：
设计三个组件：
- `RoutePaths`：路径常量
- `RouteNames`：路由名称常量（用于命名导航）
- `RouterExtension`：BuildContext 扩展，提供类型安全的导航方法

**关键代码**：
```dart
extension RouterExtension on BuildContext {
  void goEventDetail(String uid) => go('/event/$uid');

  void goEventCreate({DateTime? date}) {
    if (date != null) {
      go('${RoutePaths.eventCreate}?date=${date.toIso8601String()}');
    } else {
      go(RoutePaths.eventCreate);
    }
  }
}
```

### 问题 5: RFC 5545 RRULE 解析器的复杂性处理

**问题描述**：
RFC 5545 标准的 RRULE（重复规则）支持非常复杂的重复模式，如「每月第一个周一」「每月最后一个周五」「每两周的周一、三、五」等。如何设计一个既能完整解析这些规则、又能高效生成事件实例的解析器？

**思考过程**：
1. **BYDAY 的两种形式**：简单形式如 `MO,WE,FR` 表示每周一三五；复杂形式如 `1MO,-1FR` 表示第一个周一、最后一个周五
2. **实例生成策略**：按周期迭代生成候选日期，然后应用 BYSETPOS 筛选
3. **性能考虑**：设置最大生成数量限制，防止无限循环

**解决方案**：
设计两个独立的类：
- `RecurrenceRule`：负责 RRULE 字符串的解析和生成
- `RRuleParser`：负责根据规则生成指定范围内的事件实例日期

对于 BYDAY 的处理，区分 `byDay`（简单形式）和 `byDayRules`（带位置）两个字段。

**关键代码**：
```dart
// 获取月中第 N 个星期几的日期
static DateTime? _getNthWeekdayOfMonth(
  int year, int month, WeekDay weekDay, int position, DateTime eventStart,
) {
  if (position > 0) {
    // 正数：从月初开始数
    final firstDay = DateTime(year, month, 1);
    var daysToAdd = targetWeekday - firstDay.weekday;
    if (daysToAdd < 0) daysToAdd += 7;
    daysToAdd += (position - 1) * 7;
    // ...
  } else {
    // 负数：从月末开始数
    final lastDay = DateTime(year, month + 1, 0);
    var daysToSubtract = lastDay.weekday - targetWeekday;
    if (daysToSubtract < 0) daysToSubtract += 7;
    daysToSubtract += (-position - 1) * 7;
    // ...
  }
}
```

---

### 问题 6: UNTIL 日期的时区处理

**问题描述**：
RFC 5545 中 UNTIL 日期可以是 UTC 格式（如 `20261231T235959Z`）或本地时间格式。在解析时，如何正确处理时区转换，确保跨时区场景下的一致性？

**思考过程**：
1. UTC 格式（以 Z 结尾）需要转换为本地时间进行比较
2. 纯日期格式（如 `20261231`）表示当天的开始时间
3. 测试时需要考虑不同时区的影响

**解决方案**：
在解析时识别 UTC 标识符，使用 `.toLocal()` 转换为本地时间：

```dart
if (value.endsWith('Z')) {
  // UTC 时间 -> 本地时间
  return DateTime.utc(...).toLocal();
} else {
  // 本地时间
  return DateTime(...);
}
```

单元测试中，验证 UNTIL 的 UTC 值而非本地值，避免时区差异导致测试失败。

---

### 问题 7: 农历工具类的显示优先级设计

**问题描述**：
日历单元格空间有限，只能显示一个文本。当某天同时是节气、农历节日、公历节日时，应该显示哪个？

**思考过程**：
1. 节气是天文现象，比较稀少（每年 24 个），优先级应最高
2. 农历节日是中国传统节日，其次
3. 公历节日再次
4. 普通日期显示农历日期（初一显示月份）

**解决方案**：
定义明确的优先级顺序：节气 > 农历节日 > 公历节日 > 农历日期

```dart
static String getDisplayText(DateTime date) {
  final info = getLunarInfo(date);

  if (info.solarTerm != null) return info.solarTerm!;
  if (info.lunarFestival != null) return info.lunarFestival!;
  if (info.solarFestival != null) return info.solarFestival!;
  if (info.day == 1) return '${info.monthName}月';
  return info.dayName;
}
```

---

### 问题 8: Flutter 主题 API 变更适配

**问题描述**：
在 Flutter 3.24+ 版本中，`ThemeData.cardTheme` 期望的类型从 `CardTheme` 变为 `CardThemeData`，`DialogTheme` 同理。编译时报类型不匹配错误。

**思考过程**：
Flutter 团队正在逐步将主题类重命名为更清晰的 `*ThemeData` 后缀，以区分「主题配置数据」和「InheritedWidget」。

**解决方案**：
将 `CardTheme()` 改为 `CardThemeData()`，`DialogTheme()` 改为 `DialogThemeData()`：

```dart
// 修改前
cardTheme: CardTheme(...)

// 修改后
cardTheme: CardThemeData(...)
```

---

## 七、开发日志

### Phase 1: 项目初始化与基础架构 - 2026-01-10

#### PR 修改摘要

**新增文件：**
- `lib/core/constants/app_constants.dart` - 应用常量
- `lib/core/constants/color_constants.dart` - 颜色常量
- `lib/core/constants/db_constants.dart` - 数据库常量及建表 SQL
- `lib/core/theme/color_schemes.dart` - 配色方案
- `lib/core/theme/app_theme.dart` - 主题配置
- `lib/core/router/app_router.dart` - 路由配置
- `lib/services/database_service.dart` - 数据库服务
- `lib/viewmodels/settings_viewmodel.dart` - 设置视图模型
- `lib/app.dart` - MaterialApp 配置
- `TECHNICAL_DOC.md` - 技术文档

**修改文件：**
- `pubspec.yaml` - 添加项目依赖
- `android/app/src/main/AndroidManifest.xml` - Android 权限配置
- `ios/Runner/Info.plist` - iOS 权限配置
- `lib/main.dart` - 应用入口

**主要功能：**
1. 创建 Flutter 项目基础结构
2. 搭建 MVVM 目录架构
3. 实现亮色/深色主题系统
4. 配置 go_router 路由（含占位页面）
5. 实现 SQLite 数据库服务
6. 配置 Android/iOS 平台权限

#### 下阶段计划

**Phase 2: 数据层实现**
- [ ] 实现所有数据模型 (EventModel, CalendarModel, ReminderModel 等)
- [ ] 实现 Repository 层
- [ ] 实现 RRULE 解析器
- [ ] 实现农历工具类
- [ ] 编写单元测试

#### 风险项与阻塞项

1. **依赖版本兼容性**：部分依赖包可能存在版本冲突，需要在运行 `flutter pub get` 后确认
2. **iOS 构建环境**：需要 macOS + Xcode 环境才能构建 iOS 版本
3. **通知权限**：Android 13+ 和 iOS 需要运行时权限请求

---

### Phase 2: 数据层实现 - 2026-01-10

#### PR 修改摘要

**PR 链接**: https://github.com/contrueCT/chrono-calendar/pull/1

**新增文件：**
- `lib/data/models/event_model.dart` - RFC 5545 兼容事件模型
- `lib/data/models/calendar_model.dart` - 日历模型（支持订阅）
- `lib/data/models/reminder_model.dart` - 提醒模型（支持 VALARM）
- `lib/data/models/recurrence_rule.dart` - RRULE 重复规则解析
- `lib/data/repositories/calendar_repository.dart` - 日历仓库
- `lib/data/repositories/event_repository.dart` - 事件仓库
- `lib/core/utils/rrule_parser.dart` - 重复事件实例生成器
- `lib/core/utils/lunar_utils.dart` - 农历/节气/节日工具类
- `test/models/event_model_test.dart` - 事件模型单元测试
- `test/models/recurrence_rule_test.dart` - 重复规则单元测试

**修改文件：**
- `lib/core/theme/app_theme.dart` - 修复 Flutter 3.24+ API 兼容性
- `test/widget_test.dart` - 更新为占位测试

**提交记录（11 个细粒度提交）：**
1. feat: 实现 EventModel 数据模型
2. feat: 实现 CalendarModel 数据模型
3. feat: 实现 ReminderModel 数据模型
4. feat: 实现 RecurrenceRule 重复规则模型
5. feat: 实现 CalendarRepository 日历仓库
6. feat: 实现 EventRepository 事件仓库
7. feat: 实现 RFC 5545 RRULE 解析器
8. feat: 实现农历转换工具类
9. test: 添加数据模型单元测试
10. fix: 更新 Flutter 主题 API 类型兼容性
11. fix: 修复单元测试时区兼容性和 UNTIL 边界条件

**主要功能：**
1. 完整的 RFC 5545 事件模型（支持 UID、DTSTART、DTEND、RRULE、EXDATE 等）
2. 日历模型支持本地日历和网络订阅
3. 提醒模型支持导出 VALARM 格式
4. RRULE 解析器支持 DAILY/WEEKLY/MONTHLY/YEARLY 频率及各种修饰符
5. 农历工具类支持节气、节日、生肖、干支年等
6. 43 个单元测试全部通过

#### 下阶段计划

**Phase 3: 日历视图开发**
- [ ] 实现月视图（含农历显示）
- [ ] 实现周视图（时间轴）
- [ ] 实现日视图
- [ ] 实现视图切换
- [ ] 实现日历单元格样式

#### 风险项与阻塞项

1. **table_calendar 自定义程度**：需评估 table_calendar 组件是否满足设计需求，可能需要自定义实现部分功能
2. **周视图时间轴性能**：24 小时时间轴渲染可能需要性能优化
3. **农历库兼容性**：lunar 包在某些边界日期可能有计算偏差

---

### Phase 3: 日历视图开发 - 2026-01-10

#### PR 修改摘要

**PR 链接**: https://github.com/contrueCT/chrono-calendar/pull/2

**新增文件：**
- `lib/viewmodels/calendar_viewmodel.dart` - 日历视图模型（363行）
- `lib/views/widgets/calendar/calendar_cell.dart` - 日历单元格组件（209行）
- `lib/views/widgets/event/event_card.dart` - 事件卡片组件（364行）
- `lib/views/screens/calendar/month_view_screen.dart` - 月视图页面（360行）
- `lib/views/screens/calendar/week_view_screen.dart` - 周视图页面（545行）
- `lib/views/screens/calendar/day_view_screen.dart` - 日视图页面（659行）
- `lib/views/screens/home/home_screen.dart` - 首页（365行）

**修改文件：**
- `lib/core/router/app_router.dart` - 集成 HomeScreen 路由

**提交记录（8 个细粒度提交）：**
1. feat: 实现 CalendarViewModel 视图模型
2. feat: 实现日历单元格组件
3. feat: 实现事件卡片组件
4. feat: 实现月视图页面
5. feat: 实现周视图页面
6. feat: 实现日视图页面
7. feat: 实现首页 HomeScreen 并集成路由
8. fix: 修复视图页面编译错误和导入问题

**主要功能：**
1. CalendarViewModel 支持月/周/日视图切换，管理选中日期、事件加载、日期导航
2. CalendarCell 日历单元格支持农历显示、今日/选中高亮、事件彩色标记点
3. EventCard 系列组件：EventCard（详细卡片）、GradientEventCard（时间轴）、EventListTile（列表项）
4. MonthViewScreen 月视图：日历网格、月份导航、选中日期事件列表
5. WeekViewScreen 周视图：日期选择条、24小时时间轴、事件块显示、当前时间指示线
6. DayViewScreen 日视图：日期详情头（农历、特殊日期）、全天事件、时间轴
7. HomeScreen 首页：视图切换、导航菜单、搜索入口、FAB 添加事件

#### 下阶段计划

**Phase 4: 日程管理功能**
- [ ] 实现事件创建页面（表单、验证）
- [ ] 实现事件编辑页面
- [ ] 实现事件详情页面
- [ ] 实现重复规则配置 UI
- [ ] 实现事件删除逻辑（单次/此后/全部）

#### 风险项与阻塞项

1. **事件创建表单复杂度**：需要处理时间选择、重复规则、多提醒配置等复杂表单
2. **重复事件删除逻辑**：删除选项较多（单次/此后/全部），需要仔细处理 EXDATE 和 RRULE 修改
3. **拖拽功能依赖**：周视图/日视图的事件拖拽调整功能将在 Phase 9 实现

---

## 八、总结

本文档记录了 Chrono 日历应用的技术架构、实现细节和开发过程。随着开发进行，将持续更新遇到的问题和解决方案。

---

*文档版本：1.2*
*创建日期：2026-01-10*
*最后更新：2026-01-10（Phase 3 完成）*
