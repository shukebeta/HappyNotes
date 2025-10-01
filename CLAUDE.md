# Happy Notes - Development Guidelines

## Build & Test Commands
- Run app: `flutter run`
- Install dependencies: `flutter pub get`
- Build for Android: `flutter build apk`
- Build for iOS: `flutter build ios`
- Run all tests: `flutter test`
- Run single test: `flutter test test/path_to_test.dart`
- Run specific test group: `flutter test test/path_to_test.dart --name="Group name"`
- Analyze code: `flutter analyze`

## Code Style Guidelines
- **Naming**: Classes=PascalCase, variables/methods=camelCase, files=snake_case, private members=_prefixed
- **Imports**: Flutter packages first, project imports next, relative imports last
- **Error Handling**: Use standardized provider error handling via executeWithErrorHandling(), custom exceptions (ApiException), and Util.showError()
- **Logging**: Use SeqLogger only - SeqLogger.info() for general logs, SeqLogger.severe() for errors. NO debugPrint, NO AppLoggerInterface
- **Architecture**: Follow MVC pattern - controllers separate from UI components
- **State Management**: Provider pattern with dependency injection via get_it
- **Types**: Always specify types for parameters, return values, and variables
- **Documentation**: Document all non-trivial methods and parameters
- **Formatting**: Use standard Dart formatter with flutter_lints package rules
- **Testing**: Group related tests, use descriptive test names, mock external dependencies
- **File Editing**: Use eed (Enhanced Ed) for all file modifications - NEVER use Edit/MultiEdit tools

## Tool Usage Policy
- **BANNED TOOLS**: Edit and MultiEdit tools are prohibited due to instability
- **REQUIRED TOOL**: Use eed for all file modifications
- **Fallback**: Use sed, awk, or other command-line tools when eed is unavailable

## Enhanced Ed (eed) Usage Guidelines

### Why Use eed
- **Atomic commits**: Every edit is automatically committed, making it safe to experiment
- **Easy rollback**: `eed --undo` instantly reverts the last change
- **Precision editing**: When you know line numbers, no need to re-read entire files
- **Consistent workflow**: Every edit follows the same pattern with clear commit messages

### Learning Experience & First Steps
**Start with `eed --help`** - Don't be like me and jump in directly. Understanding the tool first saves debugging time later.

**AI vs Human editing**: As AI, we need non-interactive, atomic edits. We can't use mouse, big screens, or make multiple changes before saving like humans. Each eed command must be complete and correct in one shot.

**From beginner to proficient**: My eed journey this session: started bold but clumsy → got comfortable with basic patterns → became overconfident with complex edits → made silly mistakes when tired → learned that consistency beats cleverness.


### Practical eed Experience & Tips

正确的eed使用姿势：

eed -m 'commit message' /path/to/file <<'EOF'
# ed 编辑命令
w
q
EOF

**Pattern-based editing** (避免行号依赖):
- `/function_name/,/^}/d` - 删除整个函数
- `/import.*flutter/a` - 在import区域后添加
- `s/old_pattern/new_pattern/g` - 全局替换

**Common scenarios from real development**:
- Component creation: `a` mode for new files
- UI updates: 找到具体widget后精确替换
- Service layer: 小心API参数格式变化
- Import management: 总是在相关区域添加

**Error recovery patterns**:
- 语法错误后立即`eed --undo`
- 复杂编辑分解为多个简单步骤
- 编辑前先在脑海里"预演"整个操作

**Real lessons learned**:
- 删除代码时容易留下语法错误 → 逐段检查
- 批量替换时要考虑上下文 → 使用更精确的模式
**Key insight**: eed's atomic commits make experimentation safe, but only if you remember the basics, and, most importantly, keep edits simple and focused.
