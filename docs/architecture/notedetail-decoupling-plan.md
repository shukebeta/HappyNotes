# NoteDetail解耦重构计划

## 背景

当前架构存在跨Provider缓存问题：从TrashBin进入NoteDetail编辑时，由于NoteDetail强制使用NotesProvider，而笔记不在其缓存中，导致保存时发起错误的GET请求而失败。

## 目标

将NoteDetail重构为Pure Component，彻底解耦，使其只负责UI编辑而不执行任何数据持久化操作。

## 架构设计

### 核心理念
- **UI层**: NoteDetail - 纯UI组件，只收集用户输入
- **业务层**: Provider - 处理业务逻辑和缓存管理  
- **数据层**: Service - 处理API调用

### 数据流
```
NoteDetail (编辑) → NoteEditResult → 调用方Provider → Service → API
```

## 实施计划

### 1. 数据结构设计

创建`NoteEditResult`类：
```dart
class NoteEditResult {
  final String content;
  final bool isPrivate;
  final bool isMarkdown;
  final bool isSaved; // true=保存, false=取消
}
```

### 2. NoteDetail重构

- 移除所有Provider和Service依赖
- 移除网络请求和持久化代码
- 保存时：`navigator.pop(NoteEditResult(isSaved: true, ...))`
- 取消时：`navigator.pop(NoteEditResult(isSaved: false, ...))`

### 3. 调用方重构

各页面接收返回结果并处理：
```dart
final result = await Navigator.push(...);
if (result?.isSaved == true) {
  await provider.updateNote(noteId, result.content, ...);
}
```

### 4. 清理includeDeleted

服务器端已不需要此参数，从前端移除：
- NotesApi.get()
- NotesService.get()  
- NotesProvider.getNote()

## TODO列表

- [x] 创建计划文档
- [ ] 创建NoteEditResult数据结构
- [ ] 移除includeDeleted相关代码
- [ ] 重构NoteDetail为Pure Component
- [ ] 更新TrashBin调用方处理逻辑
- [ ] 更新HomePage调用方处理逻辑
- [ ] 更新Discovery调用方处理逻辑
- [ ] 运行测试验证功能正常
- [ ] 测试TrashBin编辑问题修复

## 预期效果

1. **解决问题**: 彻底修复TrashBin编辑失败问题
2. **架构改进**: 更清晰的职责分工和解耦
3. **可维护性**: 降低组件间耦合，提升代码质量
4. **扩展性**: 为未来功能扩展打下良好基础

## 风险控制

- 渐进式重构，保持向后兼容
- 完整测试覆盖，确保功能正常
- 详细的代码审查和验证

---

*文档创建时间: 2025-08-15*
*预计完成时间: 当前开发周期*